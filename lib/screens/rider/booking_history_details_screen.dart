import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';

class BookingHistoryDetailsScreen extends StatelessWidget {
  final BookingModel booking;
  final String role;
  final String userId;

  const BookingHistoryDetailsScreen({
    super.key,
    required this.booking,
    required this.role,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final completedAt =
        booking.updatedAt ?? booking.requestedAt ?? booking.createdAt;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F6),
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _DetailsHeaderCard(
            title: booking.customerName.isEmpty
                ? 'Order Details'
                : booking.customerName,
            status: booking.status,
            amount: 'GHS ${booking.totalPrice}',
          ),
          const SizedBox(height: 14),

          _DetailsSection(
            title: 'Route',
            children: [
              _DetailsRow(
                icon: Icons.location_on_outlined,
                label: 'Pickup',
                value: booking.pickupAddress,
              ),
              _DetailsRow(
                icon: Icons.outlined_flag_rounded,
                label: 'Drop-off',
                value: booking.customerAddress,
              ),
            ],
          ),

          const SizedBox(height: 14),

          _DetailsSection(
            title: 'Order',
            children: [
              _DetailsRow(
                icon: Icons.local_laundry_service_outlined,
                label: 'Service',
                value: booking.serviceType.replaceAll('_', ' '),
              ),
              _DetailsRow(
                icon: Icons.scale_outlined,
                label: 'Weight',
                value: '${booking.estimatedWeightKg} kg',
              ),
              _DetailsRow(
                icon: Icons.payments_outlined,
                label: 'Amount',
                value: 'GHS ${booking.totalPrice}',
              ),
              _DetailsRow(
                icon: Icons.access_time_rounded,
                label: 'Time',
                value: _formatFullDateTime(completedAt),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _DetailsSection(
            title: 'People',
            children: [
              _DetailsRow(
                icon: Icons.person_outline_rounded,
                label: 'Customer',
                value: booking.customerName,
              ),
              _DetailsRow(
                icon: Icons.phone_outlined,
                label: 'Customer Phone',
                value: booking.customerPhone,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatFullDateTime(DateTime? value) {
    if (value == null) return '—';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '${value.day} ${months[value.month - 1]} ${value.year}, $hour:$minute';
  }
}

class _DetailsHeaderCard extends StatelessWidget {
  final String title;
  final String status;
  final String amount;

  const _DetailsHeaderCard({
    required this.title,
    required this.status,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Color(0xFFE9F9EF),
            child: Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF3FC37A),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.trim().isEmpty ? 'Order Details' : title.trim(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  status.replaceAll('_', ' '),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _DetailsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailsRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cleanValue = value.trim().isEmpty ? '—' : value.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  cleanValue,
                  style: const TextStyle(
                    fontSize: 14.2,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
