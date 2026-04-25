import 'package:cloud_firestore/cloud_firestore.dart';

class LaundryModel {
  final String id;
  final String role;

  final LaundryProfile profile;
  final LaundryContact contact;
  final LaundryLocation location;
  final LaundryBusiness business;
  final LaundryOpeningHours openingHours;
  final LaundryServices services;
  final List<String> supportedAddOns;
  final LaundryPricing pricing;
  final LaundryRatings ratings;
  final LaundryStats stats;
  final LaundryOwner owner;
  final LaundryChat chat;
  final LaundryTimestamps timestamps;

  const LaundryModel({
    required this.id,
    this.role = 'laundry',
    required this.profile,
    required this.contact,
    required this.location,
    required this.business,
    required this.openingHours,
    required this.services,
    required this.supportedAddOns,
    required this.pricing,
    required this.ratings,
    required this.stats,
    required this.owner,
    required this.chat,
    required this.timestamps,
  });

  factory LaundryModel.initial({
    required String uid,
    required String laundryName,
    required String email,
  }) {
    return LaundryModel(
      id: uid,
      role: 'laundry',
      profile: LaundryProfile(
        name: laundryName,
        description: '',
        photoUrl: '',
        logoUrl: '',
        coverImageUrl: '',
      ),
      contact: LaundryContact(
        phoneNumber: '',
        email: email,
        whatsappNumber: '',
      ),
      location: const LaundryLocation(
        addressLine: '',
        latitude: 5.6396,
        longitude: -0.2525,
        digitalAddress: '',
        landmark: '',
        serviceRadiusKm: 20,
      ),
      business: const LaundryBusiness(
        isApproved: true,
        isFeatured: false,
        isOnline: true,
        acceptingOrders: true,
        acceptingAutoAssignments: true,
        maxConcurrentOrders: 10,
        currentOrderCount: 0,
        estimatedTurnaroundText: 'Same day',
      ),
      openingHours: LaundryOpeningHours.alwaysOpen(),
      services: const LaundryServices(washFold: true, washIron: true),
      supportedAddOns: const <String>[],
      pricing: const LaundryPricing(
        currency: 'GHS',
        basePricePerKg: 18,
        washIronExtraPerKg: 2,
        pickupFee: 0,
        deliveryFee: 0,
        minimumOrderPrice: 0,
        pricingNotes: '',
      ),
      ratings: const LaundryRatings(rating: 0.0, totalReviews: 0),
      stats: const LaundryStats(
        totalOrders: 0,
        completedOrders: 0,
        cancelledOrders: 0,
      ),
      owner: LaundryOwner(fullName: laundryName, phoneNumber: '', photoUrl: ''),
      chat: const LaundryChat(
        lastSeenAt: null,
        fcmTokens: <String, bool>{},
        fcmUpdatedAt: null,
      ),
      timestamps: const LaundryTimestamps(createdAt: null, updatedAt: null),
    );
  }

  LaundryModel copyWith({
    String? id,
    String? role,
    LaundryProfile? profile,
    LaundryContact? contact,
    LaundryLocation? location,
    LaundryBusiness? business,
    LaundryOpeningHours? openingHours,
    LaundryServices? services,
    List<String>? supportedAddOns,
    LaundryPricing? pricing,
    LaundryRatings? ratings,
    LaundryStats? stats,
    LaundryOwner? owner,
    LaundryChat? chat,
    LaundryTimestamps? timestamps,
  }) {
    return LaundryModel(
      id: id ?? this.id,
      role: role ?? this.role,
      profile: profile ?? this.profile,
      contact: contact ?? this.contact,
      location: location ?? this.location,
      business: business ?? this.business,
      openingHours: openingHours ?? this.openingHours,
      services: services ?? this.services,
      supportedAddOns: supportedAddOns ?? this.supportedAddOns,
      pricing: pricing ?? this.pricing,
      ratings: ratings ?? this.ratings,
      stats: stats ?? this.stats,
      owner: owner ?? this.owner,
      chat: chat ?? this.chat,
      timestamps: timestamps ?? this.timestamps,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'profile': profile.toMap(),
      'contact': contact.toMap(),
      'location': location.toMap(),
      'business': business.toMap(),
      'openingHours': openingHours.toMap(),
      'services': services.toMap(),
      'supportedAddOns': supportedAddOns,
      'pricing': pricing.toMap(),
      'ratings': ratings.toMap(),
      'stats': stats.toMap(),
      'owner': owner.toMap(),
      'chat': chat.toMap(),
      'timestamps': timestamps.toMap(),
    };
  }

  Map<String, dynamic> toCreateMap() {
    final map = toMap();

    map['timestamps'] = {
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    return map;
  }

  factory LaundryModel.fromMap(Map<String, dynamic> map) {
    return LaundryModel(
      id: _readString(map['id']),
      role: _readString(map['role'], fallback: 'laundry'),
      profile: LaundryProfile.fromMap(_readMap(map['profile'])),
      contact: LaundryContact.fromMap(_readMap(map['contact'])),
      location: LaundryLocation.fromMap(_readMap(map['location'])),
      business: LaundryBusiness.fromMap(_readMap(map['business'])),
      openingHours: LaundryOpeningHours.fromMap(_readMap(map['openingHours'])),
      services: LaundryServices.fromMap(_readMap(map['services'])),
      supportedAddOns: _readStringList(map['supportedAddOns']),
      pricing: LaundryPricing.fromMap(_readMap(map['pricing'])),
      ratings: LaundryRatings.fromMap(_readMap(map['ratings'])),
      stats: LaundryStats.fromMap(_readMap(map['stats'])),
      owner: LaundryOwner.fromMap(_readMap(map['owner'])),
      chat: LaundryChat.fromMap(_readMap(map['chat'])),
      timestamps: LaundryTimestamps.fromMap(_readMap(map['timestamps'])),
    );
  }

  factory LaundryModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return LaundryModel.fromMap(
      doc.data() ?? <String, dynamic>{},
    ).copyWith(id: doc.id);
  }
}

class LaundryProfile {
  final String name;
  final String description;
  final String photoUrl;
  final String logoUrl;
  final String coverImageUrl;

  const LaundryProfile({
    required this.name,
    required this.description,
    required this.photoUrl,
    required this.logoUrl,
    required this.coverImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'photoUrl': photoUrl,
      'logoUrl': logoUrl,
      'coverImageUrl': coverImageUrl,
    };
  }

  factory LaundryProfile.fromMap(Map<String, dynamic> map) {
    return LaundryProfile(
      name: _readString(map['name']),
      description: _readString(map['description']),
      photoUrl: _readString(map['photoUrl']),
      logoUrl: _readString(map['logoUrl']),
      coverImageUrl: _readString(map['coverImageUrl']),
    );
  }
}

class LaundryContact {
  final String phoneNumber;
  final String email;
  final String whatsappNumber;

  const LaundryContact({
    required this.phoneNumber,
    required this.email,
    required this.whatsappNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'phoneNumber': phoneNumber,
      'email': email,
      'whatsappNumber': whatsappNumber,
    };
  }

  factory LaundryContact.fromMap(Map<String, dynamic> map) {
    return LaundryContact(
      phoneNumber: _readString(map['phoneNumber']),
      email: _readString(map['email']),
      whatsappNumber: _readString(map['whatsappNumber']),
    );
  }
}

class LaundryLocation {
  final String addressLine;
  final double latitude;
  final double longitude;
  final String digitalAddress;
  final String landmark;
  final double serviceRadiusKm;

  const LaundryLocation({
    required this.addressLine,
    required this.latitude,
    required this.longitude,
    required this.digitalAddress,
    required this.landmark,
    required this.serviceRadiusKm,
  });

  Map<String, dynamic> toMap() {
    return {
      'addressLine': addressLine,
      'latitude': latitude,
      'longitude': longitude,
      'digitalAddress': digitalAddress,
      'landmark': landmark,
      'serviceRadiusKm': serviceRadiusKm,
    };
  }

  factory LaundryLocation.fromMap(Map<String, dynamic> map) {
    return LaundryLocation(
      addressLine: _readString(map['addressLine']),
      latitude: _readDouble(map['latitude'], fallback: 5.6396),
      longitude: _readDouble(map['longitude'], fallback: -0.2525),
      digitalAddress: _readString(map['digitalAddress']),
      landmark: _readString(map['landmark']),
      serviceRadiusKm: _readDouble(map['serviceRadiusKm'], fallback: 20),
    );
  }
}

class LaundryBusiness {
  final bool isApproved;
  final bool isFeatured;
  final bool isOnline;
  final bool acceptingOrders;
  final bool acceptingAutoAssignments;
  final int maxConcurrentOrders;
  final int currentOrderCount;
  final String estimatedTurnaroundText;

  const LaundryBusiness({
    required this.isApproved,
    required this.isFeatured,
    required this.isOnline,
    required this.acceptingOrders,
    required this.acceptingAutoAssignments,
    required this.maxConcurrentOrders,
    required this.currentOrderCount,
    required this.estimatedTurnaroundText,
  });

  Map<String, dynamic> toMap() {
    return {
      'isApproved': isApproved,
      'isFeatured': isFeatured,
      'isOnline': isOnline,
      'acceptingOrders': acceptingOrders,
      'acceptingAutoAssignments': acceptingAutoAssignments,
      'maxConcurrentOrders': maxConcurrentOrders,
      'currentOrderCount': currentOrderCount,
      'estimatedTurnaroundText': estimatedTurnaroundText,
    };
  }

  factory LaundryBusiness.fromMap(Map<String, dynamic> map) {
    return LaundryBusiness(
      isApproved: _readBool(map['isApproved'], fallback: true),
      isFeatured: _readBool(map['isFeatured']),
      isOnline: _readBool(map['isOnline'], fallback: true),
      acceptingOrders: _readBool(map['acceptingOrders'], fallback: true),
      acceptingAutoAssignments: _readBool(
        map['acceptingAutoAssignments'],
        fallback: true,
      ),
      maxConcurrentOrders: _readInt(map['maxConcurrentOrders'], fallback: 10),
      currentOrderCount: _readInt(map['currentOrderCount']),
      estimatedTurnaroundText: _readString(
        map['estimatedTurnaroundText'],
        fallback: 'Same day',
      ),
    );
  }
}

class LaundryOpeningHours {
  final Map<String, LaundryDayHours> days;

  const LaundryOpeningHours({required this.days});

  factory LaundryOpeningHours.alwaysOpen() {
    return const LaundryOpeningHours(
      days: {
        'mon': LaundryDayHours(isOpen: true, open: '00:00', close: '23:59'),
        'tue': LaundryDayHours(isOpen: true, open: '00:00', close: '23:59'),
        'wed': LaundryDayHours(isOpen: true, open: '00:00', close: '23:59'),
        'thu': LaundryDayHours(isOpen: true, open: '00:00', close: '23:59'),
        'fri': LaundryDayHours(isOpen: true, open: '00:00', close: '23:59'),
        'sat': LaundryDayHours(isOpen: true, open: '00:00', close: '23:59'),
        'sun': LaundryDayHours(isOpen: true, open: '00:00', close: '23:59'),
      },
    );
  }

  Map<String, dynamic> toMap() {
    return days.map((key, value) => MapEntry(key, value.toMap()));
  }

  factory LaundryOpeningHours.fromMap(Map<String, dynamic> map) {
    final defaults = LaundryOpeningHours.alwaysOpen().days;

    return LaundryOpeningHours(
      days: {
        for (final day in defaults.keys)
          day: LaundryDayHours.fromMap(
            _readMap(map[day]),
            fallback: defaults[day]!,
          ),
      },
    );
  }
}

class LaundryDayHours {
  final bool isOpen;
  final String open;
  final String close;

  const LaundryDayHours({
    required this.isOpen,
    required this.open,
    required this.close,
  });

  Map<String, dynamic> toMap() {
    return {'isOpen': isOpen, 'open': open, 'close': close};
  }

  factory LaundryDayHours.fromMap(
    Map<String, dynamic> map, {
    required LaundryDayHours fallback,
  }) {
    return LaundryDayHours(
      isOpen: _readBool(map['isOpen'], fallback: fallback.isOpen),
      open: _readString(map['open'], fallback: fallback.open),
      close: _readString(map['close'], fallback: fallback.close),
    );
  }
}

class LaundryServices {
  final bool washFold;
  final bool washIron;

  const LaundryServices({required this.washFold, required this.washIron});

  Map<String, dynamic> toMap() {
    return {'washFold': washFold, 'washIron': washIron};
  }

  factory LaundryServices.fromMap(Map<String, dynamic> map) {
    return LaundryServices(
      washFold: _readBool(map['washFold'], fallback: true),
      washIron: _readBool(map['washIron'], fallback: true),
    );
  }
}

class LaundryPricing {
  final String currency;
  final int basePricePerKg;
  final int washIronExtraPerKg;
  final int pickupFee;
  final int deliveryFee;
  final int minimumOrderPrice;
  final String pricingNotes;

  const LaundryPricing({
    required this.currency,
    required this.basePricePerKg,
    required this.washIronExtraPerKg,
    required this.pickupFee,
    required this.deliveryFee,
    required this.minimumOrderPrice,
    required this.pricingNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'currency': currency,
      'basePricePerKg': basePricePerKg,
      'washIronExtraPerKg': washIronExtraPerKg,
      'pickupFee': pickupFee,
      'deliveryFee': deliveryFee,
      'minimumOrderPrice': minimumOrderPrice,
      'pricingNotes': pricingNotes,
    };
  }

  factory LaundryPricing.fromMap(Map<String, dynamic> map) {
    return LaundryPricing(
      currency: _readString(map['currency'], fallback: 'GHS'),
      basePricePerKg: _readInt(map['basePricePerKg'], fallback: 18),
      washIronExtraPerKg: _readInt(map['washIronExtraPerKg'], fallback: 2),
      pickupFee: _readInt(map['pickupFee']),
      deliveryFee: _readInt(map['deliveryFee']),
      minimumOrderPrice: _readInt(map['minimumOrderPrice']),
      pricingNotes: _readString(map['pricingNotes']),
    );
  }
}

class LaundryRatings {
  final double rating;
  final int totalReviews;

  const LaundryRatings({required this.rating, required this.totalReviews});

  Map<String, dynamic> toMap() {
    return {'rating': rating, 'totalReviews': totalReviews};
  }

  factory LaundryRatings.fromMap(Map<String, dynamic> map) {
    return LaundryRatings(
      rating: _readDouble(map['rating']),
      totalReviews: _readInt(map['totalReviews']),
    );
  }
}

class LaundryStats {
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;

  const LaundryStats({
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalOrders': totalOrders,
      'completedOrders': completedOrders,
      'cancelledOrders': cancelledOrders,
    };
  }

  factory LaundryStats.fromMap(Map<String, dynamic> map) {
    return LaundryStats(
      totalOrders: _readInt(map['totalOrders']),
      completedOrders: _readInt(map['completedOrders']),
      cancelledOrders: _readInt(map['cancelledOrders']),
    );
  }
}

class LaundryOwner {
  final String fullName;
  final String phoneNumber;
  final String photoUrl;

  const LaundryOwner({
    required this.fullName,
    required this.phoneNumber,
    required this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
    };
  }

  factory LaundryOwner.fromMap(Map<String, dynamic> map) {
    return LaundryOwner(
      fullName: _readString(map['fullName']),
      phoneNumber: _readString(map['phoneNumber']),
      photoUrl: _readString(map['photoUrl']),
    );
  }
}

class LaundryChat {
  final DateTime? lastSeenAt;
  final Map<String, bool> fcmTokens;
  final DateTime? fcmUpdatedAt;

  const LaundryChat({
    required this.lastSeenAt,
    required this.fcmTokens,
    required this.fcmUpdatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'lastSeenAt': lastSeenAt,
      'fcmTokens': fcmTokens,
      'fcmUpdatedAt': fcmUpdatedAt,
    };
  }

  factory LaundryChat.fromMap(Map<String, dynamic> map) {
    return LaundryChat(
      lastSeenAt: _readDateTime(map['lastSeenAt']),
      fcmTokens: _readBoolMap(map['fcmTokens']),
      fcmUpdatedAt: _readDateTime(map['fcmUpdatedAt']),
    );
  }
}

class LaundryTimestamps {
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LaundryTimestamps({required this.createdAt, required this.updatedAt});

  Map<String, dynamic> toMap() {
    return {'createdAt': createdAt, 'updatedAt': updatedAt};
  }

  factory LaundryTimestamps.fromMap(Map<String, dynamic> map) {
    return LaundryTimestamps(
      createdAt: _readDateTime(map['createdAt']),
      updatedAt: _readDateTime(map['updatedAt']),
    );
  }
}

Map<String, dynamic> _readMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

String _readString(dynamic value, {String fallback = ''}) {
  if (value is String) return value;
  return fallback;
}

bool _readBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  return fallback;
}

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _readDouble(dynamic value, {double fallback = 0.0}) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

DateTime? _readDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

List<String> _readStringList(dynamic value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }

  return <String>[];
}

Map<String, bool> _readBoolMap(dynamic value) {
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val == true));
  }

  return <String, bool>{};
}
