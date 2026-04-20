class NotificationService {
  Future<void> initialize() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<void> sendOrderAcceptedNotification({
    required String userId,
    required String orderId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<void> sendRiderAssignedNotification({
    required String userId,
    required String orderId,
    required String riderId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<void> sendPaymentRequestNotification({
    required String userId,
    required String orderId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<void> sendDeliveryUpdateNotification({
    required String userId,
    required String orderId,
    required String status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}
