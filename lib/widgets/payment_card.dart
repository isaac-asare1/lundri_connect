import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/payment_model.dart';
import 'status_chip.dart';

class PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  final VoidCallback? onTap;
  final VoidCallback? onMarkPaid;

  const PaymentCard({
    super.key,
    required this.payment,
    this.onTap,
    this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final canMarkPaid =
        payment.status.toLowerCase() != 'paid' && onMarkPaid != null;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      payment.customerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  StatusChip(label: payment.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Order ID: ${payment.orderId}',
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'GHS ${payment.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (canMarkPaid) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onMarkPaid,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Mark as Paid',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
