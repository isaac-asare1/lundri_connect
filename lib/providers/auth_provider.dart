import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  User? get currentUser => _auth.currentUser;

  String _selectedRole = 'laundry';

  String get selectedRole => _selectedRole;

  void setSelectedRole(String role) {
    if (_selectedRole == role) return;
    _selectedRole = role;
    notifyListeners();
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

  /// =========================
  /// ✅ SIGN IN
  /// =========================
  Future<bool> signIn({
    required String email,
    required String password,
    required String role,
  }) async {
    _setLoading(true);
    _errorMessage = '';

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user?.uid;

      if (uid == null) {
        _errorMessage = "Authentication failed.";
        return false;
      }

      String collectionName;

      switch (role) {
        case 'rider':
          collectionName = 'riders';
          break;
        case 'laundry':
          collectionName = 'laundries';
          break;
        default:
          throw Exception("Invalid role");
      }

      final doc = await _firestore.collection(collectionName).doc(uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        _errorMessage = "You are not signed up as a $role.";
        return false;
      }

      _selectedRole = role;

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

    try {
      await _auth.signOut();
      _errorMessage = '';
    } catch (e) {
      _errorMessage = 'Failed to log out. Please try again.';
      rethrow;
    } finally {
      _setLoading(false);
    }
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
      'uid': uid,
      'ownerUid': uid,
      'fullName': fullName,
      'phoneNumber': '',
      'email': email,
      'photoUrl': '',

      'vehicleType': '',
      'vehicleMake': '',
      'vehicleColor': '',
      'plateNumber': '',

      'isApproved': false,
      'isOnline': false,
      'availabilityStatus': 'offline',
      'acceptingDeliveries': false,

      'currentBookingId': null,
      'currentLaundryId': null,
      'currentCustomerId': null,

      'currentLatitude': null,
      'currentLongitude': null,
      'lastLocationUpdatedAt': null,

      'rating': 0.0,
      'totalReviews': 0,

      'stats': {
        'totalDeliveries': 0,
        'completedDeliveries': 0,
        'cancelledDeliveries': 0,
      },

      'fcmTokens': <String, dynamic>{},
      'fcmUpdatedAt': null,

      'lastLoginAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),

      'role': 'rider',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> _buildLaundryData({
    required String uid,
    required String laundryName,
    required String email,
  }) {
    return {
      'id': uid,
      'ownerUid': uid,
      'name': laundryName,
      'description': '',
      'photoUrl': '',
      'logoUrl': '',
      'phoneNumber': '',
      'email': email,
      'addressLine': '',
      'latitude': null,
      'longitude': null,
      'serviceRadiusKm': null,
      'supportedServices': <String>[],
      'basePricePerKg': null,
      'washIronExtraPerKg': null,
      'rating': 0.0,
      'totalReviews': 0,
      'estimatedTurnaroundText': '',
      'availabilityStatus': 'closed',
      'isOpenNow': false,
      'acceptingOrders': false,
      'isApproved': false,
      'isFeatured': false,
      'currentOrderCount': 0,
      'maxConcurrentOrders': 0,
      'openingHours': <String, dynamic>{},
      'stats': {'totalOrders': 0, 'completedOrders': 0, 'cancelledOrders': 0},
      'role': 'laundry',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
