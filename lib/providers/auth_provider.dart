import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedRole = 'laundry';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  User? get currentUser => _auth.currentUser;
  String get selectedRole => _selectedRole;

  void setSelectedRole(String role) {
    if (_selectedRole == role) return;
    _selectedRole = role;
    notifyListeners();
  }

  String _generateSessionId(String uid) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return '$uid-$timestamp';
  }

  Future<void> cacheUserRole({
    required String uid,
    required String role,
    String? sessionId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('cached_uid', uid);
    await prefs.setString('user_role', role);

    if (sessionId != null && sessionId.trim().isNotEmpty) {
      await prefs.setString('active_session_id', sessionId);
    } else {
      await prefs.remove('active_session_id');
    }
  }

  Future<void> clearCachedUserRole() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('cached_uid');
    await prefs.remove('user_role');
    await prefs.remove('active_session_id');
  }

  Future<String?> _getUserRoleFromFirestore(String uid) async {
    final riderDoc = await _firestore.collection('riders').doc(uid).get();
    if (riderDoc.exists) return 'rider';

    final laundryDoc = await _firestore.collection('laundries').doc(uid).get();
    if (laundryDoc.exists) return 'laundry';

    return null;
  }

  Future<String?> resolveStoredRoleForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final cachedUid = prefs.getString('cached_uid');
    final cachedRole = prefs.getString('user_role');

    if (cachedUid == user.uid &&
        cachedRole != null &&
        cachedRole.trim().isNotEmpty) {
      _selectedRole = cachedRole;
      notifyListeners();
      return cachedRole;
    }

    final firestoreRole = await _getUserRoleFromFirestore(user.uid);

    if (firestoreRole != null) {
      _selectedRole = firestoreRole;

      try {
        await cacheUserRole(uid: user.uid, role: firestoreRole);
      } catch (_) {
        // Firestore remains the source of truth if local caching fails.
      }

      notifyListeners();
      return firestoreRole;
    }

    await clearCachedUserRole();
    await _auth.signOut();
    _selectedRole = 'laundry';
    notifyListeners();
    return null;
  }

  // ---------------------------------------------------------------------------
  // PHONE VERIFICATION
  // ---------------------------------------------------------------------------

  Future<void> sendPhoneVerificationCode({
    required String phoneNumber,
    int? forceResendingToken,
    required void Function(PhoneAuthCredential credential)
    verificationCompleted,
    required void Function(FirebaseAuthException error) verificationFailed,
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(String verificationId) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
      timeout: const Duration(seconds: 60),
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  // ---------------------------------------------------------------------------
  // SIGNUP
  // ---------------------------------------------------------------------------

  /// Finalizes registration only after the user has received an OTP and we
  /// have a [PhoneAuthCredential] created from that verification session.
  ///
  /// Flow:
  /// 1. Create the email/password Firebase user.
  /// 2. Link the verified phone credential to that SAME Firebase user.
  /// 3. Create the correct Firestore role document.
  /// 4. Cache the role locally.
  ///
  /// This keeps email/password and phone authentication on one Firebase UID.
  Future<bool> completeSignupWithVerifiedPhone({
    required String fullName,
    required String email,
    required String laundryServiceName,
    required String password,
    required String role,
    required PhoneAuthCredential phoneCredential,
  }) async {
    _setLoading(true);
    _errorMessage = '';

    User? newlyCreatedUser;
    bool firestoreProfileCreated = false;

    try {
      final selectedRole = role.trim().toLowerCase();
      final trimmedFullName = fullName.trim();
      final trimmedEmail = email.trim();
      final trimmedLaundryName = laundryServiceName.trim();

      if (selectedRole != 'rider' && selectedRole != 'laundry') {
        _errorMessage = 'Invalid role selected.';
        return false;
      }

      if (selectedRole == 'rider' && trimmedFullName.isEmpty) {
        _errorMessage = 'Please enter your full name.';
        return false;
      }

      if (selectedRole == 'laundry' && trimmedLaundryName.isEmpty) {
        _errorMessage = 'Please enter your laundry service name.';
        return false;
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      newlyCreatedUser = userCredential.user;

      if (newlyCreatedUser == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'User account could not be created.',
        );
      }

      // Link the OTP-verified phone credential to the SAME Firebase user.
      final linkedCredential = await newlyCreatedUser.linkWithCredential(
        phoneCredential,
      );

      final linkedUser = linkedCredential.user;

      if (linkedUser == null) {
        throw FirebaseAuthException(
          code: 'phone-link-failed',
          message: 'Phone verification could not be completed.',
        );
      }

      await linkedUser.reload();

      final refreshedUser = _auth.currentUser;

      if (refreshedUser == null || refreshedUser.phoneNumber == null) {
        throw FirebaseAuthException(
          code: 'phone-link-failed',
          message: 'Phone verification could not be confirmed.',
        );
      }

      final verifiedPhoneNumber = refreshedUser.phoneNumber!;

      final displayName = selectedRole == 'rider'
          ? trimmedFullName
          : trimmedLaundryName;

      await refreshedUser.updateDisplayName(displayName);

      String? riderSessionId;

      if (selectedRole == 'rider') {
        riderSessionId = _generateSessionId(refreshedUser.uid);

        await _createRiderDocument(
          uid: refreshedUser.uid,
          fullName: trimmedFullName,
          email: trimmedEmail,
          phoneNumber: verifiedPhoneNumber,
          sessionId: riderSessionId,
        );
      } else {
        await _createLaundryDocument(
          uid: refreshedUser.uid,
          laundryName: trimmedLaundryName,
          email: trimmedEmail,
          phoneNumber: verifiedPhoneNumber,
        );
      }

      firestoreProfileCreated = true;
      _selectedRole = selectedRole;

      try {
        await cacheUserRole(
          uid: refreshedUser.uid,
          role: selectedRole,
          sessionId: riderSessionId,
        );
      } catch (_) {
        // Do not fail a valid signup because SharedPreferences could not write.
        // Firestore remains the source of truth.
      }

      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e);

      if (!firestoreProfileCreated && newlyCreatedUser != null) {
        await _rollbackNewFirebaseUser(newlyCreatedUser);
      }

      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';

      if (!firestoreProfileCreated && newlyCreatedUser != null) {
        await _rollbackNewFirebaseUser(newlyCreatedUser);
      }

      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _rollbackNewFirebaseUser(User user) async {
    try {
      await user.delete();
    } catch (_) {
      try {
        await _auth.signOut();
      } catch (_) {
        // Nothing else to do here.
      }
    }

    try {
      await clearCachedUserRole();
    } catch (_) {
      // Ignore local cache cleanup failure during rollback.
    }
  }

  // ---------------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------------

  Future<bool> signIn({
    required String email,
    required String password,
    required String role,
  }) async {
    _setLoading(true);
    _errorMessage = '';

    try {
      await clearCachedUserRole();

      final selectedRole = role.trim().toLowerCase();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user?.uid;

      if (uid == null) {
        _errorMessage = 'Authentication failed.';
        await _auth.signOut();
        return false;
      }

      late final String collectionName;

      switch (selectedRole) {
        case 'rider':
          collectionName = 'riders';
          break;
        case 'laundry':
          collectionName = 'laundries';
          break;
        default:
          _errorMessage = 'Invalid role selected.';
          await _auth.signOut();
          return false;
      }

      final docRef = _firestore.collection(collectionName).doc(uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        await clearCachedUserRole();
        await _auth.signOut();

        _selectedRole = 'laundry';
        _errorMessage = 'You are not signed up as a $selectedRole.';
        notifyListeners();

        return false;
      }

      final data = doc.data() ?? {};

      if (data['isDeleted'] == true) {
        await clearCachedUserRole();
        await _auth.signOut();

        _selectedRole = 'laundry';
        _errorMessage =
            'This account has been deleted. Please contact support.';
        notifyListeners();

        return false;
      }

      // Do not block older accounts here if they were created before
      // mandatory phone verification was introduced. The app's auth/onboarding
      // gate will inspect phoneVerified/accountSetupComplete and route them to
      // the correct completion screen instead of Home.
      String? riderSessionId;

      if (selectedRole == 'rider') {
        riderSessionId = _generateSessionId(uid);

        await docRef.update({
          'auth.activeSessionId': riderSessionId,
          'auth.activeDeviceUpdatedAt': FieldValue.serverTimestamp(),
          'auth.lastLoginAt': FieldValue.serverTimestamp(),
          'timestamps.lastLoginAt': FieldValue.serverTimestamp(),
          'timestamps.lastSeen': FieldValue.serverTimestamp(),
          'timestamps.updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.update({
          'auth.lastLoginAt': FieldValue.serverTimestamp(),
          'timestamps.updatedAt': FieldValue.serverTimestamp(),
        });
      }

      _selectedRole = selectedRole;

      await cacheUserRole(
        uid: uid,
        role: selectedRole,
        sessionId: riderSessionId,
      );

      notifyListeners();

      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e);
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // VERIFY / UPGRADE AN EXISTING ACCOUNT
  // ---------------------------------------------------------------------------

  /// Links an OTP-verified phone credential to an already authenticated
  /// email/password account. This is useful for older Lundri accounts that
  /// existed before phone verification became mandatory.
  Future<bool> linkVerifiedPhoneToCurrentUser({
    required PhoneAuthCredential phoneCredential,
  }) async {
    _setLoading(true);
    _errorMessage = '';

    try {
      final user = _auth.currentUser;

      if (user == null) {
        _errorMessage = 'No authenticated user found.';
        return false;
      }

      if (user.phoneNumber == null) {
        await user.linkWithCredential(phoneCredential);
        await user.reload();
      }

      final refreshedUser = _auth.currentUser;

      if (refreshedUser == null || refreshedUser.phoneNumber == null) {
        _errorMessage = 'Phone verification could not be confirmed.';
        return false;
      }

      final role = await _getUserRoleFromFirestore(refreshedUser.uid);

      if (role == null) {
        _errorMessage = 'Unable to determine account role.';
        return false;
      }

      final collectionName = role == 'rider' ? 'riders' : 'laundries';
      final phoneNumber = refreshedUser.phoneNumber!;

      final updates = <String, dynamic>{
        'contact.phoneNumber': phoneNumber,
        'auth.phoneVerified': true,
        'auth.phoneVerifiedAt': FieldValue.serverTimestamp(),
        'timestamps.updatedAt': FieldValue.serverTimestamp(),
      };

      if (role == 'laundry') {
        updates['owner.phoneNumber'] = phoneNumber;
      }

      await _firestore
          .collection(collectionName)
          .doc(refreshedUser.uid)
          .update(updates);

      _selectedRole = role;

      try {
        await cacheUserRole(uid: refreshedUser.uid, role: role);
      } catch (_) {
        // Firestore remains the source of truth.
      }

      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e);
      return false;
    } catch (_) {
      _errorMessage = 'Unable to verify this phone number. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // ONBOARDING STATE
  // ---------------------------------------------------------------------------

  Future<bool> markAccountSetupComplete({String? role}) async {
    final user = _auth.currentUser;

    if (user == null) {
      _errorMessage = 'No authenticated user found.';
      notifyListeners();
      return false;
    }

    try {
      final resolvedRole = (role ?? await _getUserRoleFromFirestore(user.uid))
          ?.trim()
          .toLowerCase();

      if (resolvedRole != 'rider' && resolvedRole != 'laundry') {
        _errorMessage = 'Unable to determine account role.';
        notifyListeners();
        return false;
      }

      final collectionName = resolvedRole == 'rider' ? 'riders' : 'laundries';

      await _firestore.collection(collectionName).doc(user.uid).update({
        'auth.accountSetupComplete': true,
        'timestamps.updatedAt': FieldValue.serverTimestamp(),
      });

      _errorMessage = '';
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Unable to complete account setup. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> isCurrentUserPhoneVerified() async {
    final user = _auth.currentUser;
    if (user == null || user.phoneNumber == null) return false;

    final role = await _getUserRoleFromFirestore(user.uid);
    if (role == null) return false;

    final doc = await _firestore
        .collection(role == 'rider' ? 'riders' : 'laundries')
        .doc(user.uid)
        .get();

    if (!doc.exists) return false;

    final data = doc.data() ?? {};
    final authData = data['auth'];

    if (authData is! Map<String, dynamic>) return false;

    return authData['phoneVerified'] == true;
  }

  Future<bool> isCurrentUserSetupComplete() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final role = await _getUserRoleFromFirestore(user.uid);
    if (role == null) return false;

    final doc = await _firestore
        .collection(role == 'rider' ? 'riders' : 'laundries')
        .doc(user.uid)
        .get();

    if (!doc.exists) return false;

    final data = doc.data() ?? {};
    final authData = data['auth'];

    if (authData is! Map<String, dynamic>) return false;

    return authData['accountSetupComplete'] == true;
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------

  Future<void> logout() async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 2));

    try {
      await clearCachedUserRole();
      await _auth.signOut();
      _selectedRole = 'laundry';
      _errorMessage = '';
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Failed to log out. Please try again.';
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ---------------------------------------------------------------------------
  // FIRESTORE PROFILE CREATION
  // ---------------------------------------------------------------------------

  Future<void> _createRiderDocument({
    required String uid,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String sessionId,
  }) async {
    final riderData = _buildRiderData(
      uid: uid,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      sessionId: sessionId,
    );

    await _firestore.collection('riders').doc(uid).set(riderData);
  }

  Future<void> _createLaundryDocument({
    required String uid,
    required String laundryName,
    required String email,
    required String phoneNumber,
  }) async {
    final laundryData = _buildLaundryData(
      uid: uid,
      laundryName: laundryName,
      email: email,
      phoneNumber: phoneNumber,
    );

    await _firestore.collection('laundries').doc(uid).set(laundryData);
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'invalid-phone-number':
        return 'Please enter a valid phone number.';
      case 'invalid-verification-code':
        return 'The verification code is incorrect.';
      case 'session-expired':
        return 'The verification code has expired. Please request a new code.';
      case 'credential-already-in-use':
        return 'This phone number is already linked to another account.';
      case 'provider-already-linked':
        return 'This phone number is already linked to this account.';
      case 'too-many-requests':
        return 'Too many verification attempts. Please try again later.';
      case 'quota-exceeded':
        return 'The SMS verification limit has been reached. Please try again later.';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled for this Firebase project.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      case 'phone-link-failed':
        return 'Phone verification could not be completed.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Map<String, dynamic> _buildRiderData({
    required String uid,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String sessionId,
  }) {
    return {
      'id': uid,
      'role': 'rider',
      'isDeleted': false,

      'profile': {
        'fullName': fullName,
        'photoUrl': '',
        'isProfileCompleted': false,
      },

      'contact': {
        'phoneNumber': phoneNumber,
        'email': email,
        'whatsappNumber': '',
      },

      'auth': {
        'phoneVerified': true,
        'phoneVerifiedAt': FieldValue.serverTimestamp(),
        'accountSetupComplete': false,
        'activeSessionId': sessionId,
        'activeDeviceName': '',
        'activeDeviceUpdatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      },

      'location': {
        'addressLine': '',
        'geohash': null,
        'digitalAddress': '',
        'landmark': '',
        'lastLocationUpdatedAt': null,
      },

      'business': {
        'isApproved': false,
        'isOnline': false,
        'availabilityStatus': 'offline',
        'acceptingAssignments': false,
        'maxActiveRequests': 2,
        'currentActiveRequestCount': 0,
        'activeRequestIds': <String>[],
        'currentLaundryIds': <String>[],
        'currentCustomerIds': <String>[],
      },

      'vehicle': {'type': '', 'make': '', 'color': '', 'plateNumber': ''},

      'ratings': {'rating': 0.0, 'totalReviews': 0},

      'stats': {
        'totalRequestsReceived': 0,
        'acceptedRequests': 0,
        'rejectedRequests': 0,
        'totalDeliveries': 0,
        'completedDeliveries': 0,
        'cancelledDeliveries': 0,
      },

      'chat': {
        'lastSeenAt': null,
        'fcmTokens': <String, bool>{},
        'fcmUpdatedAt': null,
      },

      'timestamps': {
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      },
    };
  }

  Map<String, dynamic> _buildLaundryData({
    required String uid,
    required String laundryName,
    required String email,
    required String phoneNumber,
  }) {
    return {
      'id': uid,
      'role': 'laundry',
      'isDeleted': false,

      'profile': {
        'name': laundryName,
        'description': '',
        'photoUrl': '',
        'logoUrl': '',
        'coverImageUrl': '',
        'isProfileCompleted': false,
      },

      'contact': {
        'phoneNumber': phoneNumber,
        'email': email,
        'whatsappNumber': '',
      },

      'auth': {
        'phoneVerified': true,
        'phoneVerifiedAt': FieldValue.serverTimestamp(),
        'accountSetupComplete': false,
        'lastLoginAt': FieldValue.serverTimestamp(),
      },

      'location': {
        'addressLine': '',
        'latitude': null,
        'longitude': null,
        'geohash': null,
        'digitalAddress': '',
        'landmark': '',
        'serviceRadiusKm': 20,
      },

      'business': {
        'isApproved': true,
        'isFeatured': false,
        'isOnline': true,
        'acceptingOrders': true,
        'acceptingAutoAssignments': true,
        'maxConcurrentOrders': 10,
        'currentOrderCount': 0,
        'estimatedTurnaroundText': 'Same day',
      },

      'openingHours': {
        'mon': {'isOpen': true, 'open': '00:00', 'close': '23:59'},
        'tue': {'isOpen': true, 'open': '00:00', 'close': '23:59'},
        'wed': {'isOpen': true, 'open': '00:00', 'close': '23:59'},
        'thu': {'isOpen': true, 'open': '00:00', 'close': '23:59'},
        'fri': {'isOpen': true, 'open': '00:00', 'close': '23:59'},
        'sat': {'isOpen': true, 'open': '00:00', 'close': '23:59'},
        'sun': {'isOpen': true, 'open': '00:00', 'close': '23:59'},
      },

      'services': {'washFold': true, 'washIron': true},

      'supportedAddOns': <String>[],

      'pricing': {
        'currency': 'GHS',
        'basePricePerKg': 18,
        'washIronExtraPerKg': 2,
        'pickupFee': 0,
        'deliveryFee': 0,
        'minimumOrderPrice': 0,
        'pricingNotes': '',
      },

      'ratings': {'rating': 0.0, 'totalReviews': 0},

      'stats': {'totalOrders': 0, 'completedOrders': 0, 'cancelledOrders': 0},

      'owner': {
        'fullName': laundryName,
        'phoneNumber': phoneNumber,
        'photoUrl': '',
      },

      'chat': {
        'lastSeenAt': null,
        'fcmTokens': <String, bool>{},
        'fcmUpdatedAt': null,
      },

      'timestamps': {
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    };
  }
}
