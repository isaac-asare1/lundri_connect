class RiderRequestModel {
  final String id;
  final String orderId;
  final String riderId;
  final String customerName;
  final String pickupAddress;
  final String customerAddress;
  final String requestType;
  final String status;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  const RiderRequestModel({
    required this.id,
    required this.orderId,
    required this.riderId,
    required this.customerName,
    required this.pickupAddress,
    required this.customerAddress,
    required this.requestType,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
  });

  RiderRequestModel copyWith({
    String? id,
    String? orderId,
    String? riderId,
    String? customerName,
    String? pickupAddress,
    String? customerAddress,
    String? requestType,
    String? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
  }) {
    return RiderRequestModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      riderId: riderId ?? this.riderId,
      customerName: customerName ?? this.customerName,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      customerAddress: customerAddress ?? this.customerAddress,
      requestType: requestType ?? this.requestType,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'riderId': riderId,
      'customerName': customerName,
      'pickupAddress': pickupAddress,
      'customerAddress': customerAddress,
      'requestType': requestType,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
    };
  }

  factory RiderRequestModel.fromMap(Map<String, dynamic> map) {
    return RiderRequestModel(
      id: map['id'] as String? ?? '',
      orderId: map['orderId'] as String? ?? '',
      riderId: map['riderId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      pickupAddress: map['pickupAddress'] as String? ?? '',
      customerAddress: map['customerAddress'] as String? ?? '',
      requestType: map['requestType'] as String? ?? 'pickup',
      status: map['status'] as String? ?? 'pending',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      acceptedAt: map['acceptedAt'] != null
          ? DateTime.tryParse(map['acceptedAt'] as String)
          : null,
    );
  }
}
