import 'package:flutter/foundation.dart';

import '../models/order_model.dart';

class OrdersProvider extends ChangeNotifier {
  final List<OrderModel> _requests = [];
  final List<OrderModel> _activeOrders = [];
  bool _isLoading = false;

  List<OrderModel> get requests => List<OrderModel>.unmodifiable(_requests);
  List<OrderModel> get activeOrders =>
      List<OrderModel>.unmodifiable(_activeOrders);
  bool get isLoading => _isLoading;

  Future<void> loadDemoData() async {
    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 600));

    _requests
      ..clear()
      ..addAll([
        OrderModel(
          id: 'req_001',
          customerName: 'Ama Mensah',
          customerPhone: '+233241111111',
          pickupAddress: 'Adenta Housing Down, Accra',
          deliveryAddress: 'Adenta Housing Down, Accra',
          serviceType: 'Wash & Fold',
          totalAmount: 65,
          laundryWeight: 4.5,
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
        ),
        OrderModel(
          id: 'req_002',
          customerName: 'Kojo Asare',
          customerPhone: '+233242222222',
          pickupAddress: 'Madina Zongo Junction, Accra',
          deliveryAddress: 'Atomic Hills, Accra',
          serviceType: 'Wash & Iron',
          totalAmount: 110,
          laundryWeight: 7.2,
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        ),
      ]);

    _activeOrders
      ..clear()
      ..addAll([
        OrderModel(
          id: 'ord_001',
          customerName: 'Efua Owusu',
          customerPhone: '+233243333333',
          pickupAddress: 'East Legon, Accra',
          deliveryAddress: 'East Legon Hills, Accra',
          serviceType: 'Premium Laundry',
          totalAmount: 140,
          laundryWeight: 8.0,
          status: 'washing',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          pickupTime: DateTime.now().subtract(
            const Duration(hours: 2, minutes: 30),
          ),
        ),
        OrderModel(
          id: 'ord_002',
          customerName: 'Yaw Bediako',
          customerPhone: '+233244444444',
          pickupAddress: 'Dzorwulu, Accra',
          deliveryAddress: 'Airport Residential, Accra',
          serviceType: 'Express Clean',
          totalAmount: 90,
          laundryWeight: 5.0,
          status: 'ready',
          createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          pickupTime: DateTime.now().subtract(
            const Duration(hours: 5, minutes: 15),
          ),
        ),
      ]);

    _isLoading = false;
    notifyListeners();
  }

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
