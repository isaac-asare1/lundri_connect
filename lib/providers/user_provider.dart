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
  static const String _ridersCollection = 'riders';

  AppUserModel? _currentUser;
  BusinessInfoModel? _businessInfo;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOnline = false;
  bool _isUpdatingOnlineStatus = false;

  AppUserModel? get currentUser => _currentUser;
  BusinessInfoModel? get businessInfo => _businessInfo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _isOnline;
  bool get isUpdatingOnlineStatus => _isUpdatingOnlineStatus;

  bool get isRider => _currentUser?.role == 'rider';
  bool get isLaundry => _currentUser?.role == 'laundry';

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setOnlineStatusLoading(bool value) {
    if (_isUpdatingOnlineStatus == value) return;
    _isUpdatingOnlineStatus = value;
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

      final DocumentSnapshot<Map<String, dynamic>> laundryDoc = await _firestore
          .collection(_laundriesCollection)
          .doc(firebaseUser.uid)
          .get();

      if (laundryDoc.exists) {
        _loadLaundryFromDoc(firebaseUser, laundryDoc);
        return;
      }

      final DocumentSnapshot<Map<String, dynamic>> riderDoc = await _firestore
          .collection(_ridersCollection)
          .doc(firebaseUser.uid)
          .get();

      if (riderDoc.exists) {
        _loadRiderFromDoc(firebaseUser, riderDoc);
        return;
      }

      _currentUser = AppUserModel(
        id: firebaseUser.uid,
        fullName: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        phoneNumber: firebaseUser.phoneNumber ?? '',
        role: 'unknown',
        createdAt: DateTime.now(),
        isOnline: false,
        addressLine: '',
      );

      _businessInfo = null;
      _isOnline = false;
      _errorMessage = 'User profile not found in Firestore.';
    } catch (e) {
      _currentUser = null;
      _businessInfo = null;
      _isOnline = false;
      _errorMessage = 'Failed to load user: $e';
    } finally {
      _setLoading(false);
    }
  }

  void _loadLaundryFromDoc(
    User firebaseUser,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};

    final Map<String, dynamic> profile = _asMap(data['profile']);
    final Map<String, dynamic> contact = _asMap(data['contact']);
    final Map<String, dynamic> location = _asMap(data['location']);
    final Map<String, dynamic> business = _asMap(data['business']);
    final Map<String, dynamic> owner = _asMap(data['owner']);
    final Map<String, dynamic> timestamps = _asMap(data['timestamps']);

    _isOnline = business['isOnline'] == true;

    _currentUser = AppUserModel(
      id: firebaseUser.uid,
      fullName:
          _readString(owner['fullName']) ??
          _readString(profile['name']) ??
          firebaseUser.displayName ??
          '',
      email: _readString(contact['email']) ?? firebaseUser.email ?? '',
      phoneNumber:
          _readString(contact['phoneNumber']) ??
          _readString(owner['phoneNumber']) ??
          firebaseUser.phoneNumber ??
          '',
      role: 'laundry',
      createdAt:
          _parseDateTime(timestamps['createdAt']) ??
          _parseDateTime(data['createdAt']) ??
          DateTime.now(),
      isOnline: _isOnline,
      addressLine: _readString(location['addressLine']) ?? '',
    );

    _businessInfo = BusinessInfoModel(
      businessName: _readString(profile['name']) ?? '',
      ownerName: _readString(owner['fullName']) ?? '',
      phoneNumber:
          _readString(contact['phoneNumber']) ??
          _readString(owner['phoneNumber']) ??
          '',
      email: _readString(contact['email']) ?? '',
      address: _readString(location['addressLine']) ?? '',
      description: _readString(profile['description']) ?? '',
      pickupAvailable: false,
      deliveryAvailable: true,
    );
  }

  void _loadRiderFromDoc(
    User firebaseUser,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};

    final Map<String, dynamic> profile = _asMap(data['profile']);
    final Map<String, dynamic> contact = _asMap(data['contact']);
    final Map<String, dynamic> location = _asMap(data['location']);
    final Map<String, dynamic> business = _asMap(data['business']);
    final Map<String, dynamic> timestamps = _asMap(data['timestamps']);

    _isOnline = business['isOnline'] == true;

    _currentUser = AppUserModel(
      id: firebaseUser.uid,
      fullName:
          _readString(profile['fullName']) ?? firebaseUser.displayName ?? '',
      email: _readString(contact['email']) ?? firebaseUser.email ?? '',
      phoneNumber:
          _readString(contact['phoneNumber']) ?? firebaseUser.phoneNumber ?? '',
      role: 'rider',
      createdAt:
          _parseDateTime(timestamps['createdAt']) ??
          _parseDateTime(data['createdAt']) ??
          DateTime.now(),
      isOnline: _isOnline,
      addressLine: _readString(location['addressLine']) ?? '',
    );

    _businessInfo = null;
  }

  Future<void> setLaundryOnlineStatus(
    bool isOnline, {
    bool syncAcceptanceFlags = true,
  }) async {
    if (_currentUser == null || _isUpdatingOnlineStatus || !isLaundry) return;

    _errorMessage = null;
    _setOnlineStatusLoading(true);

    try {
      final Map<String, dynamic> updates = {
        'business.isOnline': isOnline,
        'timestamps.updatedAt': FieldValue.serverTimestamp(),
      };

      if (syncAcceptanceFlags) {
        updates['business.acceptingOrders'] = isOnline;
        updates['business.acceptingAutoAssignments'] = isOnline;
      }

      await _firestore
          .collection(_laundriesCollection)
          .doc(_currentUser!.id)
          .update(updates);

      _isOnline = isOnline;
      _currentUser = _currentUser!.copyWith(isOnline: isOnline);

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update laundry online status: $e';
      notifyListeners();
      rethrow;
    } finally {
      _setOnlineStatusLoading(false);
    }
  }

  Future<void> setRiderOnlineStatus(bool isOnline) async {
    if (_currentUser == null || _isUpdatingOnlineStatus || !isRider) return;

    _errorMessage = null;
    _setOnlineStatusLoading(true);

    try {
      await _firestore
          .collection(_ridersCollection)
          .doc(_currentUser!.id)
          .update({
            'business.isOnline': isOnline,
            'business.acceptingAssignments': isOnline,
            'business.availabilityStatus': isOnline ? 'available' : 'offline',
            'timestamps.updatedAt': FieldValue.serverTimestamp(),
          });

      _isOnline = isOnline;
      _currentUser = _currentUser!.copyWith(isOnline: isOnline);

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update rider online status: $e';
      notifyListeners();
      rethrow;
    } finally {
      _setOnlineStatusLoading(false);
    }
  }

  Future<void> updateAvailability(bool isOnline) async {
    if (isLaundry) {
      await setLaundryOnlineStatus(isOnline);
      return;
    }

    if (isRider) {
      await setRiderOnlineStatus(isOnline);
    }
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    if (isLaundry) {
      await setLaundryOnlineStatus(isOnline);
      return;
    }

    if (isRider) {
      await setRiderOnlineStatus(isOnline);
    }
  }

  Future<void> toggleOnlineStatus() async {
    if (_currentUser == null) return;

    if (isLaundry) {
      await setLaundryOnlineStatus(!_isOnline);
      return;
    }

    if (isRider) {
      await setRiderOnlineStatus(!_isOnline);
    }
  }

  Future<void> goOfflineBeforeLogout({String? role}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final String effectiveRole = (role ?? _currentUser?.role ?? '')
        .trim()
        .toLowerCase();

    try {
      if (effectiveRole == 'rider') {
        await _firestore.collection(_ridersCollection).doc(user.uid).update({
          'business.acceptingAssignments': false,
          'business.isOnline': false,
          'business.availabilityStatus': 'offline',
          'timestamps.updatedAt': FieldValue.serverTimestamp(),
        });

        _isOnline = false;
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(isOnline: false);
        }
        notifyListeners();
        return;
      }

      if (effectiveRole == 'laundry') {
        await _firestore.collection(_laundriesCollection).doc(user.uid).update({
          'business.isOnline': false,
          'business.acceptingOrders': false,
          'business.acceptingAutoAssignments': false,
          'timestamps.updatedAt': FieldValue.serverTimestamp(),
        });

        _isOnline = false;
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(isOnline: false);
        }
        notifyListeners();
      }
    } catch (_) {
      // Keep logout flow from crashing if Firestore update fails.
    }
  }

  Future<void> updateBusinessInfo(BusinessInfoModel businessInfo) async {
    if (_currentUser == null || !isLaundry) return;

    _errorMessage = null;

    try {
      await _firestore
          .collection(_laundriesCollection)
          .doc(_currentUser!.id)
          .update({
            'profile.name': businessInfo.businessName.trim(),
            'profile.description': businessInfo.description.trim(),
            'contact.phoneNumber': businessInfo.phoneNumber.trim(),
            'contact.email': businessInfo.email.trim(),
            'location.addressLine': businessInfo.address.trim(),
            'owner.fullName': businessInfo.ownerName.trim(),
            'owner.phoneNumber': businessInfo.phoneNumber.trim(),
            'timestamps.updatedAt': FieldValue.serverTimestamp(),
          });

      _businessInfo = businessInfo;

      _currentUser = _currentUser!.copyWith(
        fullName: businessInfo.ownerName.trim().isEmpty
            ? businessInfo.businessName.trim()
            : businessInfo.ownerName.trim(),
        email: businessInfo.email.trim(),
        phoneNumber: businessInfo.phoneNumber.trim(),
      );

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update business info: $e';
      notifyListeners();
    }
  }

  Future<void> updateLaundryProfile({
    required String laundryName,
    required String description,
    required String phoneNumber,
    required String email,
    required String addressLine,
    required String ownerName,
    String? ownerPhoneNumber,
    String? photoUrl,
    String? logoUrl,
    String? coverImageUrl,
    String? whatsappNumber,
    String? digitalAddress,
    String? landmark,
    double? latitude,
    double? longitude,
    int? serviceRadiusKm,
  }) async {
    if (_currentUser == null || !isLaundry) return;

    _errorMessage = null;

    try {
      await _firestore
          .collection(_laundriesCollection)
          .doc(_currentUser!.id)
          .update({
            'profile.name': laundryName.trim(),
            'profile.description': description.trim(),
            'profile.photoUrl': (photoUrl ?? '').trim(),
            'profile.logoUrl': (logoUrl ?? '').trim(),
            'profile.coverImageUrl': (coverImageUrl ?? '').trim(),
            'contact.phoneNumber': phoneNumber.trim(),
            'contact.email': email.trim(),
            'contact.whatsappNumber': (whatsappNumber ?? '').trim(),
            'location.addressLine': addressLine.trim(),
            'location.digitalAddress': (digitalAddress ?? '').trim(),
            'location.landmark': (landmark ?? '').trim(),
            'location.latitude': latitude,
            'location.longitude': longitude,
            'location.serviceRadiusKm': serviceRadiusKm ?? 10,
            'owner.fullName': ownerName.trim(),
            'owner.phoneNumber': (ownerPhoneNumber ?? phoneNumber).trim(),
            'timestamps.updatedAt': FieldValue.serverTimestamp(),
          });

      _businessInfo = BusinessInfoModel(
        businessName: laundryName.trim(),
        ownerName: ownerName.trim(),
        phoneNumber: phoneNumber.trim(),
        email: email.trim(),
        address: addressLine.trim(),
        description: description.trim(),
        pickupAvailable: true,
        deliveryAvailable: true,
      );

      _currentUser = _currentUser!.copyWith(
        fullName: ownerName.trim().isEmpty
            ? laundryName.trim()
            : ownerName.trim(),
        email: email.trim(),
        phoneNumber: phoneNumber.trim(),
        addressLine: addressLine.trim(),
      );

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update laundry profile: $e';
      notifyListeners();
    }
  }

  Future<void> updatePricing({
    num? basePricePerKg,
    num? washIronExtraPerKg,
    num? pickupFee,
    num? deliveryFee,
    num? minimumOrderPrice,
    String? pricingNotes,
  }) async {
    if (_currentUser == null || !isLaundry) return;

    _errorMessage = null;

    try {
      final Map<String, dynamic> updates = {
        'timestamps.updatedAt': FieldValue.serverTimestamp(),
      };

      if (basePricePerKg != null) {
        updates['pricing.basePricePerKg'] = basePricePerKg;
      }
      if (washIronExtraPerKg != null) {
        updates['pricing.washIronExtraPerKg'] = washIronExtraPerKg;
      }
      if (pickupFee != null) {
        updates['pricing.pickupFee'] = pickupFee;
      }
      if (deliveryFee != null) {
        updates['pricing.deliveryFee'] = deliveryFee;
      }
      if (minimumOrderPrice != null) {
        updates['pricing.minimumOrderPrice'] = minimumOrderPrice;
      }
      if (pricingNotes != null) {
        updates['pricing.pricingNotes'] = pricingNotes.trim();
      }

      await _firestore
          .collection(_laundriesCollection)
          .doc(_currentUser!.id)
          .update(updates);

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update pricing: $e';
      notifyListeners();
    }
  }

  Future<void> updateBusinessSettings({
    bool? isApproved,
    bool? isFeatured,
    bool? isOnline,
    int? maxConcurrentOrders,
    int? currentOrderCount,
    String? estimatedTurnaroundText,
    Map<String, dynamic>? openingHours,
  }) async {
    if (_currentUser == null || !isLaundry) return;

    _errorMessage = null;

    try {
      final Map<String, dynamic> updates = {
        'timestamps.updatedAt': FieldValue.serverTimestamp(),
      };

      if (isApproved != null) {
        updates['business.isApproved'] = isApproved;
      }
      if (isFeatured != null) {
        updates['business.isFeatured'] = isFeatured;
      }
      if (isOnline != null) {
        updates['business.isOnline'] = isOnline;
        updates['business.acceptingOrders'] = isOnline;
        updates['business.acceptingAutoAssignments'] = isOnline;

        _isOnline = isOnline;
        _currentUser = _currentUser!.copyWith(isOnline: isOnline);
      }
      if (maxConcurrentOrders != null) {
        updates['business.maxConcurrentOrders'] = maxConcurrentOrders;
      }
      if (currentOrderCount != null) {
        updates['business.currentOrderCount'] = currentOrderCount;
      }
      if (estimatedTurnaroundText != null) {
        updates['business.estimatedTurnaroundText'] = estimatedTurnaroundText
            .trim();
      }
      if (openingHours != null) {
        updates['openingHours'] = openingHours;
      }

      await _firestore
          .collection(_laundriesCollection)
          .doc(_currentUser!.id)
          .update(updates);

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to update business settings: $e';
      notifyListeners();
    }
  }

  void setCurrentUser(AppUserModel user) {
    _currentUser = user;
    _isOnline = user.isOnline;
    notifyListeners();
  }

  void clearUser() {
    _currentUser = null;
    _businessInfo = null;
    _errorMessage = null;
    _isOnline = false;
    _isUpdatingOnlineStatus = false;
    notifyListeners();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  String? _readString(dynamic value) {
    if (value == null) return null;
    final String result = value.toString().trim();
    return result.isEmpty ? null : result;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
