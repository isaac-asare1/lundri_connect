import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String label;

  const StatusChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.$2,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  (Color, Color) _getColors(String value) {
    switch (value.toLowerCase()) {
      case 'paid':
      case 'accepted':
      case 'completed':
      case 'ready':
      case 'success':
        return (AppColors.successBg, AppColors.success);

      case 'pending':
      case 'awaiting pickup':
      case 'washing':
        return (AppColors.warningBg, AppColors.warning);

      case 'rejected':
      case 'failed':
      case 'cancelled':
      case 'canceled':
        return (AppColors.errorBg, AppColors.error);

      default:
        return (AppColors.pendingBg, AppColors.textSecondary);
    }
  }
}
