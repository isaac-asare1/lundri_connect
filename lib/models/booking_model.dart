import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String laundryId;
  final String customerId;
  final String? pickupRiderId;
  final String? deliveryRiderId;

  final String serviceType;
  final List<String> supportedAddOns;

  final String weightRange;
  final double estimatedWeightKg;
  final double basePricePerKg;
  final double washIronExtraPerKg;
  final double addOnTotal;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final String currency;

  final String pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String pickupContactName;
  final String pickupContactPhone;
  final String pickupDate;
  final String pickupTimeSlot;
  final String pickupNotes;

  final String dropoffAddress;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final String dropoffContactName;
  final String dropoffContactPhone;
  final String dropoffNotes;

  final String laundryName;
  final String laundryPhoneNumber;
  final String laundryPhotoUrl;
  final String laundryAddressLine;

  final String customerName;
  final String customerPhone;
  final String customerPhotoUrl;

  final String status;
  final String paymentStatus;

  final DateTime? requestedAt;
  final DateTime? laundryAcceptedAt;
  final DateTime? pickupRiderAssignedAt;
  final DateTime? pickupStartedAt;
  final DateTime? pickedUpAt;
  final DateTime? arrivedAtLaundryAt;
  final DateTime? processingStartedAt;
  final DateTime? readyForDropoffAt;
  final DateTime? deliveryRiderAssignedAt;
  final DateTime? deliveryStartedAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;

  final String cancelledBy;
  final String cancellationReason;

  final String customerNote;
  final String laundryNote;
  final String pickupRiderNote;
  final String deliveryRiderNote;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BookingModel({
    required this.id,
    required this.laundryId,
    required this.customerId,
    required this.pickupRiderId,
    required this.deliveryRiderId,
    required this.serviceType,
    required this.supportedAddOns,
    required this.weightRange,
    required this.estimatedWeightKg,
    required this.basePricePerKg,
    required this.washIronExtraPerKg,
    required this.addOnTotal,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.currency,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.pickupContactName,
    required this.pickupContactPhone,
    required this.pickupDate,
    required this.pickupTimeSlot,
    required this.pickupNotes,
    required this.dropoffAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.dropoffContactName,
    required this.dropoffContactPhone,
    required this.dropoffNotes,
    required this.laundryName,
    required this.laundryPhoneNumber,
    required this.laundryPhotoUrl,
    required this.laundryAddressLine,
    required this.customerName,
    required this.customerPhone,
    required this.customerPhotoUrl,
    required this.status,
    required this.paymentStatus,
    required this.requestedAt,
    required this.laundryAcceptedAt,
    required this.pickupRiderAssignedAt,
    required this.pickupStartedAt,
    required this.pickedUpAt,
    required this.arrivedAtLaundryAt,
    required this.processingStartedAt,
    required this.readyForDropoffAt,
    required this.deliveryRiderAssignedAt,
    required this.deliveryStartedAt,
    required this.deliveredAt,
    required this.cancelledAt,
    required this.cancelledBy,
    required this.cancellationReason,
    required this.customerNote,
    required this.laundryNote,
    required this.pickupRiderNote,
    required this.deliveryRiderNote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map, String docId) {
    final pickup = _asMap(map['pickup']);
    final dropoff = _asMap(map['dropoff']);
    final laundrySnapshot = _asMap(map['laundrySnapshot']);
    final customerSnapshot = _asMap(map['customerSnapshot']);
    final timeline = _asMap(map['timeline']);
    final cancellation = _asMap(map['cancellation']);
    final notes = _asMap(map['notes']);

    return BookingModel(
      id: docId,
      laundryId: _readString(map['laundryId']),
      customerId: _readString(map['customerId']),
      pickupRiderId: _readNullableString(map['pickupRiderId']),
      deliveryRiderId: _readNullableString(map['deliveryRiderId']),

      serviceType: _readString(map['serviceType']),
      supportedAddOns: _readStringList(map['supportedAddOns']),

      weightRange: _readString(map['weightRange']),
      estimatedWeightKg: _readDouble(map['estimatedWeightKg']),
      basePricePerKg: _readDouble(map['basePricePerKg']),
      washIronExtraPerKg: _readDouble(map['washIronExtraPerKg']),
      addOnTotal: _readDouble(map['addOnTotal']),
      subtotal: _readDouble(map['subtotal']),
      deliveryFee: _readDouble(map['deliveryFee']),
      totalAmount: _readDouble(map['totalAmount']),
      currency: _readString(map['currency'], fallback: 'GHS'),

      pickupAddress: _readString(pickup['addressLine']),
      pickupLatitude: _readNullableDouble(pickup['latitude']),
      pickupLongitude: _readNullableDouble(pickup['longitude']),
      pickupContactName: _readString(pickup['contactName']),
      pickupContactPhone: _readString(pickup['contactPhone']),
      pickupDate: _readString(pickup['pickupDate']),
      pickupTimeSlot: _readString(pickup['pickupTimeSlot']),
      pickupNotes: _readString(pickup['pickupNotes']),

      dropoffAddress: _readString(dropoff['addressLine']),
      dropoffLatitude: _readNullableDouble(dropoff['latitude']),
      dropoffLongitude: _readNullableDouble(dropoff['longitude']),
      dropoffContactName: _readString(dropoff['contactName']),
      dropoffContactPhone: _readString(dropoff['contactPhone']),
      dropoffNotes: _readString(dropoff['dropoffNotes']),

      laundryName: _readString(laundrySnapshot['name']),
      laundryPhoneNumber: _readString(laundrySnapshot['phoneNumber']),
      laundryPhotoUrl: _readString(laundrySnapshot['photoUrl']),
      laundryAddressLine: _readString(laundrySnapshot['addressLine']),

      customerName: _readString(
        customerSnapshot['name'],
        fallback: 'Unknown Customer',
      ),
      customerPhone: _readString(customerSnapshot['phoneNumber']),
      customerPhotoUrl: _readString(customerSnapshot['photoUrl']),

      status: _readString(map['status']),
      paymentStatus: _readString(map['paymentStatus']),

      requestedAt: _parseTimestamp(timeline['requestedAt']),
      laundryAcceptedAt: _parseTimestamp(timeline['laundryAcceptedAt']),
      pickupRiderAssignedAt: _parseTimestamp(timeline['pickupRiderAssignedAt']),
      pickupStartedAt: _parseTimestamp(timeline['pickupStartedAt']),
      pickedUpAt: _parseTimestamp(timeline['pickedUpAt']),
      arrivedAtLaundryAt: _parseTimestamp(timeline['arrivedAtLaundryAt']),
      processingStartedAt: _parseTimestamp(timeline['processingStartedAt']),
      readyForDropoffAt: _parseTimestamp(timeline['readyForDropoffAt']),
      deliveryRiderAssignedAt: _parseTimestamp(
        timeline['deliveryRiderAssignedAt'],
      ),
      deliveryStartedAt: _parseTimestamp(timeline['deliveryStartedAt']),
      deliveredAt: _parseTimestamp(timeline['deliveredAt']),
      cancelledAt: _parseTimestamp(timeline['cancelledAt']),

      cancelledBy: _readString(cancellation['cancelledBy']),
      cancellationReason: _readString(cancellation['reason']),

      customerNote: _readString(notes['customer']),
      laundryNote: _readString(notes['laundry']),
      pickupRiderNote: _readString(notes['pickupRider']),
      deliveryRiderNote: _readString(notes['deliveryRider']),

      createdAt:
          _parseTimestamp(map['createdAt']) ??
          _parseTimestamp(timeline['requestedAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return <String, dynamic>{};
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  static String? _readNullableString(dynamic value) {
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }

  static double _readDouble(dynamic value, {double fallback = 0.0}) {
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
