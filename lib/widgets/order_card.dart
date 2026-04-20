import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/order_model.dart';
import 'status_chip.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;
  final VoidCallback? onRequestRider;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onRequestRider,
  });

  @override
  Widget build(BuildContext context) {
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
                      order.customerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  StatusChip(label: order.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.serviceType,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              _InfoLine(
                icon: Icons.local_laundry_service_outlined,
                text:
                    '${order.laundryWeight.toStringAsFixed(1)} kg • GHS ${order.totalAmount.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 8),
              _InfoLine(
                icon: Icons.location_on_outlined,
                text: order.deliveryAddress,
              ),
              if (onRequestRider != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: onRequestRider,
                    icon: const Icon(Icons.delivery_dining_outlined),
                    label: const Text(
                      'Request Rider',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: AppColors.softPink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
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

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

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
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
