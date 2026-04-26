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

  Future<void> cacheUserRole({
    required String uid,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_uid', uid);
    await prefs.setString('user_role', role);
  }

  Future<void> clearCachedUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_uid');
    await prefs.remove('user_role');
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
      await cacheUserRole(uid: user.uid, role: firestoreRole);
      notifyListeners();
      return firestoreRole;
    }

    await clearCachedUserRole();
    await _auth.signOut();
    _selectedRole = 'laundry';
    notifyListeners();
    return null;
  }

  Future<bool> signup({
    required String fullName,
    required String email,
    required String laundryServiceName,
    required String password,
    required String role,
  }) async {
    _setLoading(true);
    _errorMessage = '';

    try {
      final String trimmedFullName = fullName.trim();
      final String trimmedEmail = email.trim();
      final String trimmedLaundryName = laundryServiceName.trim();

      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: trimmedEmail,
            password: password,
          );

      final user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'User account could not be created.',
        );
      }

      final String displayName = role == 'rider'
          ? trimmedFullName
          : trimmedLaundryName;

      await user.updateDisplayName(displayName);

      if (role == 'rider') {
        await _createRiderDocument(
          uid: user.uid,
          fullName: trimmedFullName,
          email: trimmedEmail,
        );
      } else {
        await _createLaundryDocument(
          uid: user.uid,
          laundryName: trimmedLaundryName,
          email: trimmedEmail,
        );
      }

      _selectedRole = role;
      await cacheUserRole(uid: user.uid, role: role);
      notifyListeners();

      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
    required String role,
  }) async {
    _setLoading(true);
    _errorMessage = '';

    try {
      await clearCachedUserRole();

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
      switch (role) {
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

      final doc = await _firestore.collection(collectionName).doc(uid).get();

      if (!doc.exists) {
        await clearCachedUserRole();
        await _auth.signOut();
        _selectedRole = 'laundry';
        _errorMessage = 'You are not signed up as a $role.';
        notifyListeners();
        return false;
      }

      _selectedRole = role;
      await cacheUserRole(uid: uid, role: role);
      notifyListeners();

      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapFirebaseAuthError(e);
      return false;
    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    await Future.delayed(const Duration(seconds: 2));

    try {
      await clearCachedUserRole();
      await _auth.signOut();
      _selectedRole = 'laundry';
      _errorMessage = '';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to log out. Please try again.';
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _createRiderDocument({
    required String uid,
    required String fullName,
    required String email,
  }) async {
    final Map<String, dynamic> riderData = _buildRiderData(
      uid: uid,
      fullName: fullName,
      email: email,
    );

    await _firestore.collection('riders').doc(uid).set(riderData);
  }

  Future<void> _createLaundryDocument({
    required String uid,
    required String laundryName,
    required String email,
  }) async {
    final Map<String, dynamic> laundryData = _buildLaundryData(
      uid: uid,
      laundryName: laundryName,
      email: email,
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
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
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
  }) {
    return {
      'id': uid,
      'role': 'rider',
      'profile': {'fullName': fullName, 'photoUrl': ''},
      'contact': {'phoneNumber': '', 'email': email, 'whatsappNumber': ''},
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
  }) {
    return {
      'id': uid,
      'role': 'laundry',
      'profile': {
        'name': laundryName,
        'description': '',
        'photoUrl': '',
        'logoUrl': '',
        'coverImageUrl': '',
      },
      'contact': {'phoneNumber': '', 'email': email, 'whatsappNumber': ''},
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
      'owner': {'fullName': laundryName, 'phoneNumber': '', 'photoUrl': ''},
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
