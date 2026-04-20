class OrderModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final String pickupAddress;
  final String deliveryAddress;
  final String serviceType;
  final double totalAmount;
  final double laundryWeight;
  final String status;
  final DateTime createdAt;
  final DateTime? pickupTime;
  final DateTime? completedAt;

  const OrderModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.serviceType,
    required this.totalAmount,
    required this.laundryWeight,
    required this.status,
    required this.createdAt,
    this.pickupTime,
    this.completedAt,
  });

  OrderModel copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? pickupAddress,
    String? deliveryAddress,
    String? serviceType,
    double? totalAmount,
    double? laundryWeight,
    String? status,
    DateTime? createdAt,
    DateTime? pickupTime,
    DateTime? completedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      serviceType: serviceType ?? this.serviceType,
      totalAmount: totalAmount ?? this.totalAmount,
      laundryWeight: laundryWeight ?? this.laundryWeight,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      pickupTime: pickupTime ?? this.pickupTime,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'serviceType': serviceType,
      'totalAmount': totalAmount,
      'laundryWeight': laundryWeight,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'pickupTime': pickupTime?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      pickupAddress: map['pickupAddress'] as String? ?? '',
      deliveryAddress: map['deliveryAddress'] as String? ?? '',
      serviceType: map['serviceType'] as String? ?? '',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      laundryWeight: (map['laundryWeight'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'pending',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      pickupTime: map['pickupTime'] != null
          ? DateTime.tryParse(map['pickupTime'] as String)
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.tryParse(map['completedAt'] as String)
          : null,
    );
  }
}
