import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String bookingCode;

  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerPhotoUrl;

  final String? laundryId;
  final String? laundryName;
  final String? laundryPhone;
  final String? laundryPhotoUrl;

  final String? laundrySnapshotId;
  final String? laundrySnapshotName;
  final String? laundrySnapshotPhone;
  final String? laundrySnapshotPhotoUrl;
  final String? laundrySnapshotAddressLine;

  final String serviceType;
  final List<String> selectedAddOns;

  final int estimatedWeightKg;
  final int? actualWeightKg;

  final String pickupAddress;
  final String pickupSubtitle;
  final double? pickupLatitude;
  final double? pickupLongitude;

  final String deliveryAddress;
  final String deliverySubtitle;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final bool isSameAsPickup;

  final int basePrice;
  final int addOnsPrice;
  final int pickupFee;
  final int deliveryFee;
  final int totalPrice;
  final String currency;

  final String status;

  final String paymentMethod;
  final String paymentStatus;
  final String? paymentTransactionRef;
  final DateTime? paidAt;

  final String? pickupRiderId;
  final String? pickupRiderName;
  final String? pickupRiderPhone;
  final String? pickupRiderPhotoUrl;
  final String? pickupRiderVehicleType;
  final String? pickupRiderPlateNumber;
  final DateTime? pickupRiderAssignedAt;
  final DateTime? pickupRiderPickedUpAt;

  final String? deliveryRiderId;
  final String? deliveryRiderName;
  final String? deliveryRiderPhone;
  final String? deliveryRiderPhotoUrl;
  final String? deliveryRiderVehicleType;
  final String? deliveryRiderPlateNumber;
  final DateTime? deliveryRiderAssignedAt;
  final DateTime? deliveryRiderDeliveredAt;

  final bool hasUnreadForCustomer;
  final bool hasUnreadForLaundry;
  final String lastMessage;
  final DateTime? lastMessageAt;

  final bool assignedAutomatically;
  final DateTime? assignedAt;

  final String? offeredLaundryId;
  final DateTime? offeredAt;
  final DateTime? offerExpiresAt;

  final List<String> rejectedLaundryIds;
  final int assignmentAttempts;
  final DateTime? lastAssignmentAttemptAt;
  final int maxSearchRadiusKm;

  final DateTime? requestedAt;
  final DateTime? acceptedAt;
  final DateTime? pickupStartedAt;
  final DateTime? arrivedAtLaundryAt;
  final DateTime? processingStartedAt;
  final DateTime? readyForDropoffAt;
  final DateTime? deliveryStartedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  final String customerNotes;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BookingModel({
    required this.id,
    required this.bookingCode,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.customerPhotoUrl,
    required this.laundryId,
    required this.laundryName,
    required this.laundryPhone,
    required this.laundryPhotoUrl,
    required this.laundrySnapshotId,
    required this.laundrySnapshotName,
    required this.laundrySnapshotPhone,
    required this.laundrySnapshotPhotoUrl,
    required this.laundrySnapshotAddressLine,
    required this.serviceType,
    required this.selectedAddOns,
    required this.estimatedWeightKg,
    required this.actualWeightKg,
    required this.pickupAddress,
    required this.pickupSubtitle,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.deliveryAddress,
    required this.deliverySubtitle,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.isSameAsPickup,
    required this.basePrice,
    required this.addOnsPrice,
    required this.pickupFee,
    required this.deliveryFee,
    required this.totalPrice,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paymentTransactionRef,
    required this.paidAt,
    required this.pickupRiderId,
    required this.pickupRiderName,
    required this.pickupRiderPhone,
    required this.pickupRiderPhotoUrl,
    required this.pickupRiderVehicleType,
    required this.pickupRiderPlateNumber,
    required this.pickupRiderAssignedAt,
    required this.pickupRiderPickedUpAt,
    required this.deliveryRiderId,
    required this.deliveryRiderName,
    required this.deliveryRiderPhone,
    required this.deliveryRiderPhotoUrl,
    required this.deliveryRiderVehicleType,
    required this.deliveryRiderPlateNumber,
    required this.deliveryRiderAssignedAt,
    required this.deliveryRiderDeliveredAt,
    required this.hasUnreadForCustomer,
    required this.hasUnreadForLaundry,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.assignedAutomatically,
    required this.assignedAt,
    required this.offeredLaundryId,
    required this.offeredAt,
    required this.offerExpiresAt,
    required this.rejectedLaundryIds,
    required this.assignmentAttempts,
    required this.lastAssignmentAttemptAt,
    required this.maxSearchRadiusKm,
    required this.requestedAt,
    required this.acceptedAt,
    required this.pickupStartedAt,
    required this.arrivedAtLaundryAt,
    required this.processingStartedAt,
    required this.readyForDropoffAt,
    required this.deliveryStartedAt,
    required this.completedAt,
    required this.cancelledAt,
    required this.customerNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String docId) {
    final pickupAddressMap = _asMap(map['pickupAddress']);
    final deliveryAddressMap = _asMap(map['deliveryAddress']);
    final pricingMap = _asMap(map['pricing']);
    final paymentMap = _asMap(map['payment']);
    final pickupRiderMap = _asMap(map['pickupRider']);
    final deliveryRiderMap = _asMap(map['deliveryRider']);
    final chatMap = _asMap(map['chat']);
    final laundryAssignmentMap = _asMap(map['laundryAssignment']);
    final laundryOfferMap = _asMap(map['laundryOffer']);
    final laundrySnapshotMap = _asMap(map['laundrySnapshot']);
    final searchMetaMap = _asMap(map['searchMeta']);
    final timelineMap = _asMap(map['timeline']);

    final items = map['items'] is List ? map['items'] as List : <dynamic>[];
    final firstItem = items.isNotEmpty && items.first is Map<String, dynamic>
        ? items.first as Map<String, dynamic>
        : <String, dynamic>{};

    return BookingModel(
      id: docId,
      bookingCode: _readString(map['bookingCode']),

      customerId: _readString(map['customerId']),
      customerName: _readString(map['customerName']),
      customerPhone: _readString(map['customerPhone']),
      customerPhotoUrl: _readString(map['customerPhotoUrl']),

      laundryId: _readNullableString(map['laundryId']),
      laundryName: _readNullableString(map['laundryName']),
      laundryPhone: _readNullableString(map['laundryPhone']),
      laundryPhotoUrl: _readNullableString(map['laundryPhotoUrl']),

      laundrySnapshotId: _readNullableString(laundrySnapshotMap['laundryId']),
      laundrySnapshotName: _readNullableString(
        laundrySnapshotMap['laundryName'],
      ),
      laundrySnapshotPhone: _readNullableString(
        laundrySnapshotMap['laundryPhone'],
      ),
      laundrySnapshotPhotoUrl: _readNullableString(
        laundrySnapshotMap['laundryPhotoUrl'],
      ),
      laundrySnapshotAddressLine: _readNullableString(
        laundrySnapshotMap['addressLine'],
      ),

      serviceType: _readString(map['serviceType']),
      selectedAddOns: _readStringList(map['selectedAddOns']),

      estimatedWeightKg: _readInt(firstItem['estimatedWeightKg']),
      actualWeightKg: _readNullableInt(firstItem['actualWeightKg']),

      pickupAddress: _readString(pickupAddressMap['address']),
      pickupSubtitle: _readString(pickupAddressMap['subtitle']),
      pickupLatitude: _readNullableDouble(pickupAddressMap['latitude']),
      pickupLongitude: _readNullableDouble(pickupAddressMap['longitude']),

      deliveryAddress: _readString(deliveryAddressMap['address']),
      deliverySubtitle: _readString(deliveryAddressMap['subtitle']),
      deliveryLatitude: _readNullableDouble(deliveryAddressMap['latitude']),
      deliveryLongitude: _readNullableDouble(deliveryAddressMap['longitude']),
      isSameAsPickup: _readBool(deliveryAddressMap['isSameAsPickup']),

      basePrice: _readInt(pricingMap['basePrice']),
      addOnsPrice: _readInt(pricingMap['addOnsPrice']),
      pickupFee: _readInt(pricingMap['pickupFee']),
      deliveryFee: _readInt(pricingMap['deliveryFee']),
      totalPrice: _readInt(pricingMap['totalPrice']),
      currency: _readString(pricingMap['currency'], fallback: 'GHS'),

      status: _readString(map['status']),

      paymentMethod: _readString(paymentMap['method']),
      paymentStatus: _readString(paymentMap['status']),
      paymentTransactionRef: _readNullableString(paymentMap['transactionRef']),
      paidAt: _parseTimestamp(paymentMap['paidAt']),

      pickupRiderId: _readNullableString(pickupRiderMap['riderId']),
      pickupRiderName: _readNullableString(pickupRiderMap['fullName']),
      pickupRiderPhone: _readNullableString(pickupRiderMap['phoneNumber']),
      pickupRiderPhotoUrl: _readNullableString(pickupRiderMap['photoUrl']),
      pickupRiderVehicleType: _readNullableString(
        pickupRiderMap['vehicleType'],
      ),
      pickupRiderPlateNumber: _readNullableString(
        pickupRiderMap['plateNumber'],
      ),
      pickupRiderAssignedAt: _parseTimestamp(pickupRiderMap['assignedAt']),
      pickupRiderPickedUpAt: _parseTimestamp(pickupRiderMap['pickedUpAt']),

      deliveryRiderId: _readNullableString(deliveryRiderMap['riderId']),
      deliveryRiderName: _readNullableString(deliveryRiderMap['fullName']),
      deliveryRiderPhone: _readNullableString(deliveryRiderMap['phoneNumber']),
      deliveryRiderPhotoUrl: _readNullableString(deliveryRiderMap['photoUrl']),
      deliveryRiderVehicleType: _readNullableString(
        deliveryRiderMap['vehicleType'],
      ),
      deliveryRiderPlateNumber: _readNullableString(
        deliveryRiderMap['plateNumber'],
      ),
      deliveryRiderAssignedAt: _parseTimestamp(deliveryRiderMap['assignedAt']),
      deliveryRiderDeliveredAt: _parseTimestamp(
        deliveryRiderMap['deliveredAt'],
      ),

      hasUnreadForCustomer: _readBool(chatMap['hasUnreadForCustomer']),
      hasUnreadForLaundry: _readBool(chatMap['hasUnreadForLaundry']),
      lastMessage: _readString(chatMap['lastMessage']),
      lastMessageAt: _parseTimestamp(chatMap['lastMessageAt']),

      assignedAutomatically: _readBool(
        laundryAssignmentMap['assignedAutomatically'],
      ),
      assignedAt: _parseTimestamp(laundryAssignmentMap['assignedAt']),

      offeredLaundryId: _readNullableString(
        laundryOfferMap['offeredLaundryId'],
      ),
      offeredAt: _parseTimestamp(laundryOfferMap['offeredAt']),
      offerExpiresAt: _parseTimestamp(laundryOfferMap['offerExpiresAt']),

      rejectedLaundryIds: _readStringList(map['rejectedLaundryIds']),
      assignmentAttempts: _readInt(searchMetaMap['assignmentAttempts']),
      lastAssignmentAttemptAt: _parseTimestamp(
        searchMetaMap['lastAssignmentAttemptAt'],
      ),
      maxSearchRadiusKm: _readInt(searchMetaMap['maxSearchRadiusKm']),

      requestedAt: _parseTimestamp(timelineMap['requestedAt']),
      acceptedAt: _parseTimestamp(timelineMap['acceptedAt']),
      pickupStartedAt: _parseTimestamp(timelineMap['pickupStartedAt']),
      arrivedAtLaundryAt: _parseTimestamp(timelineMap['arrivedAtLaundryAt']),
      processingStartedAt: _parseTimestamp(timelineMap['processingStartedAt']),
      readyForDropoffAt: _parseTimestamp(timelineMap['readyForDropoffAt']),
      deliveryStartedAt: _parseTimestamp(timelineMap['deliveryStartedAt']),
      completedAt: _parseTimestamp(timelineMap['completedAt']),
      cancelledAt: _parseTimestamp(timelineMap['cancelledAt']),

      customerNotes: _readString(map['customerNotes']),

      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  bool get isIncomingOffer => status == 'offered_to_laundry';
  bool get isActiveLaundryOrder {
    switch (status) {
      case 'pending':
      case 'looking_for_pickup_rider':
      case 'pickup_rider_assigned':
      case 'pickup_started':
      case 'arrived_at_laundry':
      case 'processing':
      case 'ready_for_dropoff':
      case 'delivery_in_progress':
      case 'completed':
        return true;
      default:
        return false;
    }
  }

  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isNoLaundryFound => status == 'no_laundry_found';

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

  static String? _readNullableString(dynamic value) {
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
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

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
