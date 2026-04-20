import 'package:flutter/foundation.dart';

import '../models/rider_request_model.dart';

class RiderProvider extends ChangeNotifier {
  final List<RiderRequestModel> _riderRequests = [];
  bool _isLoading = false;
  bool _isOnline = true;

  List<RiderRequestModel> get riderRequests =>
      List<RiderRequestModel>.unmodifiable(_riderRequests);
  bool get isLoading => _isLoading;
  bool get isOnline => _isOnline;

  Future<void> loadDemoRiderRequests() async {
    _isLoading = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 500));

    _riderRequests
      ..clear()
      ..addAll([
        RiderRequestModel(
          id: 'ride_001',
          orderId: 'ord_001',
          riderId: 'rider_001',
          customerName: 'Efua Owusu',
          pickupAddress: 'Lundri Hub, East Legon',
          deliveryAddress: 'East Legon Hills, Accra',
          requestType: 'delivery',
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        ),
        RiderRequestModel(
          id: 'ride_002',
          orderId: 'ord_003',
          riderId: 'rider_001',
          customerName: 'Naa Ayele',
          pickupAddress: 'Spintex Road, Accra',
          deliveryAddress: 'Teshie Nungua Estates, Accra',
          requestType: 'pickup',
          status: 'accepted',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          acceptedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        ),
      ]);

    _isLoading = false;
    notifyListeners();
  }

  void toggleOnlineStatus(bool value) {
    _isOnline = value;
    notifyListeners();
  }

  void createRiderRequest({
    required String orderId,
    required String riderId,
    required String customerName,
    required String pickupAddress,
    required String deliveryAddress,
    required String requestType,
  }) {
    _riderRequests.insert(
      0,
      RiderRequestModel(
        id: 'ride_${DateTime.now().millisecondsSinceEpoch}',
        orderId: orderId,
        riderId: riderId,
        customerName: customerName,
        pickupAddress: pickupAddress,
        deliveryAddress: deliveryAddress,
        requestType: requestType,
        status: 'pending',
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void acceptRiderRequest(String requestId) {
    final index = _riderRequests.indexWhere(
      (request) => request.id == requestId,
    );
    if (index == -1) return;

    _riderRequests[index] = _riderRequests[index].copyWith(
      status: 'accepted',
      acceptedAt: DateTime.now(),
    );

    notifyListeners();
  }

  void completeRiderRequest(String requestId) {
    final index = _riderRequests.indexWhere(
      (request) => request.id == requestId,
    );
    if (index == -1) return;

    _riderRequests[index] = _riderRequests[index].copyWith(status: 'completed');

    notifyListeners();
  }

  void clearRequests() {
    _riderRequests.clear();
    notifyListeners();
  }
}
