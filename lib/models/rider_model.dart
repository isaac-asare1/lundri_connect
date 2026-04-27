import 'package:cloud_firestore/cloud_firestore.dart';

class RiderModel {
  final String id;
  final String role;
  final bool isProfileCompleted;

  final String fullName;
  final String photoUrl;

  final String phoneNumber;
  final String email;
  final String whatsappNumber;

  final String addressLine;
  final double? latitude;
  final double? longitude;
  final String digitalAddress;
  final String landmark;
  final DateTime? lastLocationUpdatedAt;

  final bool isApproved;
  final bool isOnline;
  final String availabilityStatus;
  final bool acceptingAssignments;
  final int maxActiveRequests;
  final int currentActiveRequestCount;
  final List<String> activeRequestIds;
  final List<String> currentLaundryIds;
  final List<String> currentCustomerIds;

  final String vehicleType;
  final String vehicleMake;
  final String vehicleColor;
  final String plateNumber;

  final double rating;
  final int totalReviews;

  final int totalRequestsReceived;
  final int acceptedRequests;
  final int rejectedRequests;
  final int totalDeliveries;
  final int completedDeliveries;
  final int cancelledDeliveries;

  final DateTime? chatLastSeenAt;
  final Map<String, bool> fcmTokens;
  final DateTime? fcmUpdatedAt;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastLoginAt;
  final DateTime? lastSeen;

  const RiderModel({
    required this.id,
    required this.role,
    required this.isProfileCompleted,
    required this.fullName,
    required this.photoUrl,
    required this.phoneNumber,
    required this.email,
    required this.whatsappNumber,
    required this.addressLine,
    required this.latitude,
    required this.longitude,
    required this.digitalAddress,
    required this.landmark,
    required this.lastLocationUpdatedAt,
    required this.isApproved,
    required this.isOnline,
    required this.availabilityStatus,
    required this.acceptingAssignments,
    required this.maxActiveRequests,
    required this.currentActiveRequestCount,
    required this.activeRequestIds,
    required this.currentLaundryIds,
    required this.currentCustomerIds,
    required this.vehicleType,
    required this.vehicleMake,
    required this.vehicleColor,
    required this.plateNumber,
    required this.rating,
    required this.totalReviews,
    required this.totalRequestsReceived,
    required this.acceptedRequests,
    required this.rejectedRequests,
    required this.totalDeliveries,
    required this.completedDeliveries,
    required this.cancelledDeliveries,
    required this.chatLastSeenAt,
    required this.fcmTokens,
    required this.fcmUpdatedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLoginAt,
    required this.lastSeen,
  });

  factory RiderModel.fromMap(Map<String, dynamic> map, String docId) {
    final profile = _asMap(map['profile']);
    final contact = _asMap(map['contact']);
    final location = _asMap(map['location']);
    final business = _asMap(map['business']);
    final vehicle = _asMap(map['vehicle']);
    final ratings = _asMap(map['ratings']);
    final stats = _asMap(map['stats']);
    final chat = _asMap(map['chat']);
    final timestamps = _asMap(map['timestamps']);

    return RiderModel(
      id: _readString(map['id'], fallback: docId),
      role: _readString(map['role'], fallback: 'rider'),
      isProfileCompleted: _readBool(map['isProfileCompleted'], fallback: false),

      fullName: _readString(profile['fullName']),
      photoUrl: _readString(profile['photoUrl']),

      phoneNumber: _readString(contact['phoneNumber']),
      email: _readString(contact['email']),
      whatsappNumber: _readString(contact['whatsappNumber']),

      addressLine: _readString(location['addressLine']),
      latitude: _readNullableDouble(location['latitude']),
      longitude: _readNullableDouble(location['longitude']),
      digitalAddress: _readString(location['digitalAddress']),
      landmark: _readString(location['landmark']),
      lastLocationUpdatedAt: _parseTimestamp(location['lastLocationUpdatedAt']),

      isApproved: _readBool(business['isApproved']),
      isOnline: _readBool(business['isOnline']),
      availabilityStatus: _readString(
        business['availabilityStatus'],
        fallback: 'offline',
      ),
      acceptingAssignments: _readBool(business['acceptingAssignments']),
      maxActiveRequests: _readInt(business['maxActiveRequests'], fallback: 2),
      currentActiveRequestCount: _readInt(
        business['currentActiveRequestCount'],
      ),
      activeRequestIds: _readStringList(business['activeRequestIds']),
      currentLaundryIds: _readStringList(business['currentLaundryIds']),
      currentCustomerIds: _readStringList(business['currentCustomerIds']),

      vehicleType: _readString(vehicle['type']),
      vehicleMake: _readString(vehicle['make']),
      vehicleColor: _readString(vehicle['color']),
      plateNumber: _readString(vehicle['plateNumber']),

      rating: _readDouble(ratings['rating']),
      totalReviews: _readInt(ratings['totalReviews']),

      totalRequestsReceived: _readInt(stats['totalRequestsReceived']),
      acceptedRequests: _readInt(stats['acceptedRequests']),
      rejectedRequests: _readInt(stats['rejectedRequests']),
      totalDeliveries: _readInt(stats['totalDeliveries']),
      completedDeliveries: _readInt(stats['completedDeliveries']),
      cancelledDeliveries: _readInt(stats['cancelledDeliveries']),

      chatLastSeenAt: _parseTimestamp(chat['lastSeenAt']),
      fcmTokens: _readBoolMap(chat['fcmTokens']),
      fcmUpdatedAt: _parseTimestamp(chat['fcmUpdatedAt']),

      createdAt: _parseTimestamp(timestamps['createdAt']),
      updatedAt: _parseTimestamp(timestamps['updatedAt']),
      lastLoginAt: _parseTimestamp(timestamps['lastLoginAt']),
      lastSeen: _parseTimestamp(timestamps['lastSeen']),
    );
  }

  factory RiderModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return RiderModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'isProfileCompleted': isProfileCompleted,
      'profile': {'fullName': fullName, 'photoUrl': photoUrl},
      'contact': {
        'phoneNumber': phoneNumber,
        'email': email,
        'whatsappNumber': whatsappNumber,
      },
      'location': {
        'addressLine': addressLine,
        'latitude': latitude,
        'longitude': longitude,
        'digitalAddress': digitalAddress,
        'landmark': landmark,
        'lastLocationUpdatedAt': lastLocationUpdatedAt == null
            ? null
            : Timestamp.fromDate(lastLocationUpdatedAt!),
      },
      'business': {
        'isApproved': isApproved,
        'isOnline': isOnline,
        'availabilityStatus': availabilityStatus,
        'acceptingAssignments': acceptingAssignments,
        'maxActiveRequests': maxActiveRequests,
        'currentActiveRequestCount': currentActiveRequestCount,
        'activeRequestIds': activeRequestIds,
        'currentLaundryIds': currentLaundryIds,
        'currentCustomerIds': currentCustomerIds,
      },
      'vehicle': {
        'type': vehicleType,
        'make': vehicleMake,
        'color': vehicleColor,
        'plateNumber': plateNumber,
      },
      'ratings': {'rating': rating, 'totalReviews': totalReviews},
      'stats': {
        'totalRequestsReceived': totalRequestsReceived,
        'acceptedRequests': acceptedRequests,
        'rejectedRequests': rejectedRequests,
        'totalDeliveries': totalDeliveries,
        'completedDeliveries': completedDeliveries,
        'cancelledDeliveries': cancelledDeliveries,
      },
      'chat': {
        'lastSeenAt': chatLastSeenAt == null
            ? null
            : Timestamp.fromDate(chatLastSeenAt!),
        'fcmTokens': fcmTokens,
        'fcmUpdatedAt': fcmUpdatedAt == null
            ? null
            : Timestamp.fromDate(fcmUpdatedAt!),
      },
      'timestamps': {
        'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
        'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
        'lastLoginAt': lastLoginAt == null
            ? null
            : Timestamp.fromDate(lastLoginAt!),
        'lastSeen': lastSeen == null ? null : Timestamp.fromDate(lastSeen!),
      },
    };
  }

  RiderModel copyWith({
    String? id,
    String? role,
    bool? isProfileCompleted,
    String? fullName,
    String? photoUrl,
    String? phoneNumber,
    String? email,
    String? whatsappNumber,
    String? addressLine,
    double? latitude,
    double? longitude,
    String? digitalAddress,
    String? landmark,
    DateTime? lastLocationUpdatedAt,
    bool? isApproved,
    bool? isOnline,
    String? availabilityStatus,
    bool? acceptingAssignments,
    int? maxActiveRequests,
    int? currentActiveRequestCount,
    List<String>? activeRequestIds,
    List<String>? currentLaundryIds,
    List<String>? currentCustomerIds,
    String? vehicleType,
    String? vehicleMake,
    String? vehicleColor,
    String? plateNumber,
    double? rating,
    int? totalReviews,
    int? totalRequestsReceived,
    int? acceptedRequests,
    int? rejectedRequests,
    int? totalDeliveries,
    int? completedDeliveries,
    int? cancelledDeliveries,
    DateTime? chatLastSeenAt,
    Map<String, bool>? fcmTokens,
    DateTime? fcmUpdatedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    DateTime? lastSeen,
  }) {
    return RiderModel(
      id: id ?? this.id,
      role: role ?? this.role,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      addressLine: addressLine ?? this.addressLine,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      digitalAddress: digitalAddress ?? this.digitalAddress,
      landmark: landmark ?? this.landmark,
      lastLocationUpdatedAt:
          lastLocationUpdatedAt ?? this.lastLocationUpdatedAt,
      isApproved: isApproved ?? this.isApproved,
      isOnline: isOnline ?? this.isOnline,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      acceptingAssignments: acceptingAssignments ?? this.acceptingAssignments,
      maxActiveRequests: maxActiveRequests ?? this.maxActiveRequests,
      currentActiveRequestCount:
          currentActiveRequestCount ?? this.currentActiveRequestCount,
      activeRequestIds: activeRequestIds ?? this.activeRequestIds,
      currentLaundryIds: currentLaundryIds ?? this.currentLaundryIds,
      currentCustomerIds: currentCustomerIds ?? this.currentCustomerIds,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleMake: vehicleMake ?? this.vehicleMake,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      plateNumber: plateNumber ?? this.plateNumber,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalRequestsReceived:
          totalRequestsReceived ?? this.totalRequestsReceived,
      acceptedRequests: acceptedRequests ?? this.acceptedRequests,
      rejectedRequests: rejectedRequests ?? this.rejectedRequests,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
      completedDeliveries: completedDeliveries ?? this.completedDeliveries,
      cancelledDeliveries: cancelledDeliveries ?? this.cancelledDeliveries,
      chatLastSeenAt: chatLastSeenAt ?? this.chatLastSeenAt,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      fcmUpdatedAt: fcmUpdatedAt ?? this.fcmUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  bool get canAcceptMoreRequests =>
      isApproved &&
      isOnline &&
      acceptingAssignments &&
      currentActiveRequestCount < maxActiveRequests;

  bool get isBusy => currentActiveRequestCount >= maxActiveRequests;

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double _readDouble(dynamic value, {double fallback = 0.0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static double? _readNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static bool _readBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    return fallback;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  static Map<String, bool> _readBoolMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value.map((key, val) => MapEntry(key, val == true));
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val == true));
    }
    return <String, bool>{};
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
