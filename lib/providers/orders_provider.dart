import 'package:flutter/foundation.dart';

import '../models/order_model.dart';

class OrdersProvider extends ChangeNotifier {
  final List<OrderModel> _requests = [];
  final List<OrderModel> _activeOrders = [];

  List<OrderModel> get requests => List<OrderModel>.unmodifiable(_requests);
  List<OrderModel> get activeOrders =>
      List<OrderModel>.unmodifiable(_activeOrders);

  void acceptRequest(String requestId) {
    final index = _requests.indexWhere((order) => order.id == requestId);
    if (index == -1) return;

    final acceptedOrder = _requests[index].copyWith(
      status: 'accepted',
      pickupTime: DateTime.now(),
    );

    _requests.removeAt(index);
    _activeOrders.insert(0, acceptedOrder);
    notifyListeners();
  }

  void rejectRequest(String requestId) {
    _requests.removeWhere((order) => order.id == requestId);
    notifyListeners();
  }

  void updateOrderStatus(String orderId, String status) {
    final index = _activeOrders.indexWhere((order) => order.id == orderId);
    if (index == -1) return;

    _activeOrders[index] = _activeOrders[index].copyWith(
      status: status,
      completedAt: status == 'completed' ? DateTime.now() : null,
    );

    notifyListeners();
  }

  void addRequest(OrderModel order) {
    _requests.insert(0, order);
    notifyListeners();
  }

  void addActiveOrder(OrderModel order) {
    _activeOrders.insert(0, order);
    notifyListeners();
  }

  void clearAll() {
    _requests.clear();
    _activeOrders.clear();
    notifyListeners();
  }
}
