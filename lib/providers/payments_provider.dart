import 'package:flutter/foundation.dart';

import '../models/payment_model.dart';

class PaymentsProvider extends ChangeNotifier {
  final List<PaymentModel> _payments = [];
  bool _isLoading = false;

  List<PaymentModel> get payments => List<PaymentModel>.unmodifiable(_payments);
  bool get isLoading => _isLoading;

  Future<void> loadDemoPayments() async {
    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 500));

    _payments
      ..clear()
      ..addAll([
        PaymentModel(
          id: 'pay_001',
          orderId: 'ord_001',
          customerName: 'Efua Owusu',
          amount: 140,
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        PaymentModel(
          id: 'pay_002',
          orderId: 'ord_002',
          customerName: 'Yaw Bediako',
          amount: 90,
          status: 'paid',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          paidAt: DateTime.now().subtract(const Duration(hours: 18)),
        ),
      ]);

    _isLoading = false;
    notifyListeners();
  }

  void sendPaymentRequest(String orderId, String customerName, double amount) {
    _payments.insert(
      0,
      PaymentModel(
        id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
        orderId: orderId,
        customerName: customerName,
        amount: amount,
        status: 'pending',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void markAsPaid(String paymentId) {
    final index = _payments.indexWhere((payment) => payment.id == paymentId);
    if (index == -1) return;

    _payments[index] = _payments[index].copyWith(
      status: 'paid',
      paidAt: DateTime.now(),
    );

    notifyListeners();
  }

  void clearPayments() {
    _payments.clear();
    notifyListeners();
  }
}
