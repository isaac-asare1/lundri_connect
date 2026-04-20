import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user_model.dart';
import '../models/business_info_model.dart';

class UserProvider extends ChangeNotifier {
  UserProvider({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const String _laundriesCollection = 'laundries';

  AppUserModel? _currentUser;
  BusinessInfoModel? _businessInfo;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOnline = false;

  AppUserModel? get currentUser => _currentUser;
  BusinessInfoModel? get businessInfo => _businessInfo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _isOnline;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final User? firebaseUser = _auth.currentUser;

      if (firebaseUser == null) {
        _currentUser = null;
        _businessInfo = null;
        _isOnline = false;
        _errorMessage = 'No authenticated user found.';
        return;
      }

      final doc = await _firestore
          .collection(_laundriesCollection)
          .doc(firebaseUser.uid)
          .get();

      if (!doc.exists) {
        _currentUser = AppUserModel(
          id: firebaseUser.uid,
          fullName: firebaseUser.displayName ?? '',
          email: firebaseUser.email ?? '',
          phoneNumber: firebaseUser.phoneNumber ?? '',
          role: 'operator',
          createdAt: DateTime.now(),
          isAvailable: false,
        );

        _businessInfo = null;
        _isOnline = false;
        _errorMessage = 'Laundry profile not found in Firestore.';
        return;
      }

      final data = doc.data() ?? <String, dynamic>{};

      _isOnline = data['isOnline'] == true;

      _currentUser = AppUserModel(
        id: firebaseUser.uid,
        fullName:
            _readString(data['fullName']) ??
            _readString(data['ownerName']) ??
            firebaseUser.displayName ??
            '',
        email:
            _readString(data['email']) ??
            _readString(data['businessEmail']) ??
            firebaseUser.email ??
            '',
        phoneNumber:
            _readString(data['phoneNumber']) ??
            _readString(data['businessPhoneNumber']) ??
            firebaseUser.phoneNumber ??
            '',
        role: _readString(data['role']) ?? 'operator',
        createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
        isAvailable: data['isAvailable'] == true,
      );

      _businessInfo = BusinessInfoModel(
        businessName: _readString(data['businessName']) ?? '',
        ownerName:
            _readString(data['ownerName']) ??
            _readString(data['fullName']) ??
            '',
        phoneNumber:
            _readString(data['businessPhoneNumber']) ??
            _readString(data['phoneNumber']) ??
            '',
        email:
            _readString(data['businessEmail']) ??
            _readString(data['email']) ??
            '',
        address: _readString(data['address']) ?? '',
        description: _readString(data['description']) ?? '',
        pickupAvailable: data['pickupAvailable'] == true,
        deliveryAvailable: data['deliveryAvailable'] == true,
      );
    } catch (e) {
      _currentUser = null;
      _businessInfo = null;
      _isOnline = false;
      _errorMessage = 'Failed to load user: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAvailability(bool isAvailable) async {
    if (_currentUser == null) return;

    _errorMessage = null;

    try {
      await _firestore
          .collection(_laundriesCollection)
          .doc(_currentUser!.id)
          .update({
            'isAvailable': isAvailable,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      _currentUser = _currentUser!.copyWith(isAvailable: isAvailable);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update availability: $e';
      notifyListeners();
    }
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    if (_currentUser == null) return;

    _errorMessage = null;

    try {
      await _firestore
          .collection(_laundriesCollection)
          .doc(_currentUser!.id)
          .update({
            'isOnline': isOnline,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      _isOnline = isOnline;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update online status: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleOnlineStatus() async {
    await updateOnlineStatus(!_isOnline);
  }

  Future<void> updateBusinessInfo(BusinessInfoModel businessInfo) async {
    if (_currentUser == null) return;

    _errorMessage = null;

    try {
      await _firestore
          .collection(_laundriesCollection)
          .doc(_currentUser!.id)
          .update({
            'businessName': businessInfo.businessName,
            'ownerName': businessInfo.ownerName,
            'businessPhoneNumber': businessInfo.phoneNumber,
            'businessEmail': businessInfo.email,
            'address': businessInfo.address,
            'description': businessInfo.description,
            'pickupAvailable': businessInfo.pickupAvailable,
            'deliveryAvailable': businessInfo.deliveryAvailable,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      _businessInfo = businessInfo;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update business info: $e';
      notifyListeners();
    }
  }

  void setCurrentUser(AppUserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    _businessInfo = null;
    _errorMessage = null;
    _isOnline = false;
    notifyListeners();
  }

  String? _readString(dynamic value) {
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
