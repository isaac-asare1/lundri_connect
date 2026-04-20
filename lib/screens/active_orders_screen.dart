import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/orders_provider.dart';
import '../providers/rider_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/order_card.dart';

class ActiveOrdersScreen extends StatefulWidget {
  const ActiveOrdersScreen({super.key});

  @override
  State<ActiveOrdersScreen> createState() => _ActiveOrdersScreenState();
}

class _ActiveOrdersScreenState extends State<ActiveOrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<OrdersProvider>().loadDemoData());
  }

  @override
  Widget build(BuildContext context) {
    final ordersProvider = context.watch<OrdersProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Active Orders')),
      body: ordersProvider.isLoading
          ? const LoadingWidget(message: 'Loading active orders...')
          : ordersProvider.activeOrders.isEmpty
          ? const _EmptyOrdersView()
          : RefreshIndicator(
              onRefresh: ordersProvider.loadDemoData,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                itemCount: ordersProvider.activeOrders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final order = ordersProvider.activeOrders[index];

                  return OrderCard(
                    order: order,
                    onRequestRider: () {
                      context.read<RiderProvider>().createRiderRequest(
                        orderId: order.id,
                        riderId: 'rider_001',
                        customerName: order.customerName,
                        pickupAddress: order.pickupAddress,
                        deliveryAddress: order.deliveryAddress,
                        requestType: 'delivery',
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rider requested for delivery'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _EmptyOrdersView extends StatelessWidget {
  const _EmptyOrdersView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_laundry_service_outlined,
              size: 56,
              color: AppColors.iconMuted,
            ),
            SizedBox(height: 14),
            Text(
              'No active orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Accepted and ongoing laundry jobs will show here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
