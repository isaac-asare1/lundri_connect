import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/order_model.dart';
import 'custom_button.dart';
import 'status_chip.dart';

class RequestCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const RequestCard({
    super.key,
    required this.order,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopRow(order: order),
            const SizedBox(height: 14),
            Text(
              order.customerName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              order.serviceType,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            _InfoRow(icon: Icons.phone_outlined, text: order.customerPhone),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.location_on_outlined,
              text: order.pickupAddress,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.local_laundry_service_outlined,
              text:
                  '${order.laundryWeight.toStringAsFixed(1)} kg • GHS ${order.totalAmount.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Accept',
                    onPressed: onAccept,
                    height: 52,
                    borderRadius: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  final OrderModel order;

  const _TopRow({required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'New Request',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        StatusChip(label: order.status),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.iconMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
