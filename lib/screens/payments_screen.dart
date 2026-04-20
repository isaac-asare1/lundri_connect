import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/payments_provider.dart';
import '../widgets/loading_widget.dart';
import '../widgets/payment_card.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<PaymentsProvider>().loadDemoPayments());
  }

  @override
  Widget build(BuildContext context) {
    final paymentsProvider = context.watch<PaymentsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: paymentsProvider.isLoading
          ? const LoadingWidget(message: 'Loading payments...')
          : paymentsProvider.payments.isEmpty
          ? const _EmptyPaymentsView()
          : RefreshIndicator(
              onRefresh: paymentsProvider.loadDemoPayments,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                itemCount: paymentsProvider.payments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final payment = paymentsProvider.payments[index];

                  return PaymentCard(
                    payment: payment,
                    onMarkPaid: () {
                      context.read<PaymentsProvider>().markAsPaid(payment.id);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Payment marked as paid'),
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

class _EmptyPaymentsView extends StatelessWidget {
  const _EmptyPaymentsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.payments_outlined, size: 56, color: AppColors.iconMuted),
            SizedBox(height: 14),
            Text(
              'No payments yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Payment requests and completed payments will appear here.',
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
