class FirestoreService {
  Future<List<Map<String, dynamic>>> getRequests() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    return <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'req_001',
        'customerName': 'Ama Mensah',
        'serviceType': 'Wash & Fold',
        'status': 'pending',
      },
      <String, dynamic>{
        'id': 'req_002',
        'customerName': 'Kojo Asare',
        'serviceType': 'Wash & Iron',
        'status': 'pending',
      },
    ];
  }

  Future<List<Map<String, dynamic>>> getActiveOrders() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    return <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'ord_001',
        'customerName': 'Efua Owusu',
        'serviceType': 'Premium Laundry',
        'status': 'washing',
      },
      <String, dynamic>{
        'id': 'ord_002',
        'customerName': 'Yaw Bediako',
        'serviceType': 'Express Clean',
        'status': 'ready',
      },
    ];
  }

  Future<List<Map<String, dynamic>>> getPayments() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    return <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'pay_001',
        'customerName': 'Efua Owusu',
        'amount': 140.0,
        'status': 'pending',
      },
      <String, dynamic>{
        'id': 'pay_002',
        'customerName': 'Yaw Bediako',
        'amount': 90.0,
        'status': 'paid',
      },
    ];
  }

  Future<void> saveBusinessInfo(Map<String, dynamic> data) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  Future<void> createRiderRequest(Map<String, dynamic> data) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }
}
