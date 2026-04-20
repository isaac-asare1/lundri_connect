class PaymentModel {
  final String id;
  final String orderId;
  final String customerName;
  final double amount;
  final String status;
  final DateTime createdAt;
  final DateTime? paidAt;

  const PaymentModel({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.paidAt,
  });

  PaymentModel copyWith({
    String? id,
    String? orderId,
    String? customerName,
    double? amount,
    String? status,
    DateTime? createdAt,
    DateTime? paidAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      customerName: customerName ?? this.customerName,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'customerName': customerName,
      'amount': amount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] as String? ?? '',
      orderId: map['orderId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'pending',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      paidAt: map['paidAt'] != null
          ? DateTime.tryParse(map['paidAt'] as String)
          : null,
    );
  }
}
