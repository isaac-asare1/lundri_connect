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
    final finalTime =
        booking.completedAt ??
        booking.cancelledAt ??
        booking.updatedAt ??
        booking.requestedAt ??
        booking.createdAt;

    final addOns = booking.selectedAddOns.isEmpty
        ? 'None'
        : booking.selectedAddOns.map((e) => e.replaceAll('_', ' ')).join(', ');

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
            title: booking.bookingCode.isNotEmpty
                ? booking.bookingCode
                : 'Customer Order',
            subtitle: booking.customerName,
            status: booking.status,
            amount: '${booking.currency} ${booking.totalPrice}',
          ),
          const SizedBox(height: 14),

          _DetailsSection(
            title: 'Route',
            children: [
              _DetailsRow(
                icon: Icons.location_on_outlined,
                label: 'Customer Pickup',
                value: booking.pickupAddress,
              ),
              if (booking.pickupSubtitle.isNotEmpty)
                _DetailsRow(
                  icon: Icons.place_outlined,
                  label: 'Pickup Area',
                  value: booking.pickupSubtitle,
                ),
              _DetailsRow(
                icon: Icons.outlined_flag_rounded,
                label: 'Customer Drop-off',
                value: booking.customerAddress,
              ),
              if (booking.deliverySubtitle.isNotEmpty)
                _DetailsRow(
                  icon: Icons.place_outlined,
                  label: 'Drop-off Area',
                  value: booking.deliverySubtitle,
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
                icon: Icons.add_circle_outline_rounded,
                label: 'Add-ons',
                value: addOns,
              ),
              _DetailsRow(
                icon: Icons.scale_outlined,
                label: 'Weight',
                value: booking.actualWeightKg != null
                    ? '${booking.actualWeightKg} kg actual'
                    : '${booking.estimatedWeightKg} kg estimated',
              ),
              if (booking.customerNotes.trim().isNotEmpty)
                _DetailsRow(
                  icon: Icons.notes_rounded,
                  label: 'Customer Notes',
                  value: booking.customerNotes,
                ),
            ],
          ),

          const SizedBox(height: 14),

          _DetailsSection(
            title: 'Pricing',
            children: [
              _DetailsRow(
                icon: Icons.payments_outlined,
                label: 'Base Price',
                value: '${booking.currency} ${booking.basePrice}',
              ),
              _DetailsRow(
                icon: Icons.add_card_rounded,
                label: 'Add-ons',
                value: '${booking.currency} ${booking.addOnsPrice}',
              ),
              _DetailsRow(
                icon: Icons.receipt_long_rounded,
                label: 'Total',
                value: '${booking.currency} ${booking.totalPrice}',
              ),
            ],
          ),

          const SizedBox(height: 14),

          _DetailsSection(
            title: 'Customer',
            children: [
              _DetailsRow(
                icon: Icons.person_outline_rounded,
                label: 'Name',
                value: booking.customerName,
              ),
              _DetailsRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: booking.customerPhone,
              ),
            ],
          ),

          const SizedBox(height: 14),

          _DetailsSection(
            title: 'Riders',
            children: [
              _DetailsRow(
                icon: Icons.two_wheeler_rounded,
                label: 'Pickup Rider',
                value: _riderText(
                  name: booking.pickupRiderName,
                  phone: booking.pickupRiderPhone,
                  vehicle: booking.pickupRiderVehicleType,
                  plate: booking.pickupRiderPlateNumber,
                ),
              ),
              _DetailsRow(
                icon: Icons.delivery_dining_rounded,
                label: 'Delivery Rider',
                value: _riderText(
                  name: booking.deliveryRiderName,
                  phone: booking.deliveryRiderPhone,
                  vehicle: booking.deliveryRiderVehicleType,
                  plate: booking.deliveryRiderPlateNumber,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _DetailsSection(
            title: 'Payment',
            children: [
              _DetailsRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Method',
                value: booking.paymentMethod,
              ),
              _DetailsRow(
                icon: Icons.verified_outlined,
                label: 'Status',
                value: booking.paymentStatus,
              ),
              if ((booking.paymentTransactionRef ?? '').trim().isNotEmpty)
                _DetailsRow(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Reference',
                  value: booking.paymentTransactionRef ?? '',
                ),
            ],
          ),

          const SizedBox(height: 14),

          _DetailsSection(
            title: 'Timeline',
            children: [
              _DetailsRow(
                icon: Icons.schedule_rounded,
                label: 'Requested',
                value: _formatFullDateTime(booking.requestedAt),
              ),
              if (booking.acceptedAt != null)
                _DetailsRow(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Accepted',
                  value: _formatFullDateTime(booking.acceptedAt),
                ),
              if (booking.pickupStartedAt != null)
                _DetailsRow(
                  icon: Icons.directions_bike_rounded,
                  label: 'Pickup Started',
                  value: _formatFullDateTime(booking.pickupStartedAt),
                ),
              if (booking.arrivedAtLaundryAt != null)
                _DetailsRow(
                  icon: Icons.storefront_rounded,
                  label: 'Arrived At Laundry',
                  value: _formatFullDateTime(booking.arrivedAtLaundryAt),
                ),
              if (booking.processingStartedAt != null)
                _DetailsRow(
                  icon: Icons.local_laundry_service_rounded,
                  label: 'Processing Started',
                  value: _formatFullDateTime(booking.processingStartedAt),
                ),
              if (booking.readyForDropoffAt != null)
                _DetailsRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Ready For Drop-off',
                  value: _formatFullDateTime(booking.readyForDropoffAt),
                ),
              if (booking.deliveryStartedAt != null)
                _DetailsRow(
                  icon: Icons.local_shipping_outlined,
                  label: 'Delivery Started',
                  value: _formatFullDateTime(booking.deliveryStartedAt),
                ),
              _DetailsRow(
                icon: booking.isCancelled
                    ? Icons.cancel_outlined
                    : Icons.done_all_rounded,
                label: booking.isCancelled ? 'Cancelled' : 'Final Update',
                value: _formatFullDateTime(finalTime),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _riderText({
    required String? name,
    required String? phone,
    required String? vehicle,
    required String? plate,
  }) {
    final parts = <String>[
      if ((name ?? '').trim().isNotEmpty) name!.trim(),
      if ((phone ?? '').trim().isNotEmpty) phone!.trim(),
      if ((vehicle ?? '').trim().isNotEmpty) vehicle!.trim(),
      if ((plate ?? '').trim().isNotEmpty) plate!.trim(),
    ];

    return parts.isEmpty ? '—' : parts.join(' • ');
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
  final String subtitle;
  final String status;
  final String amount;

  const _DetailsHeaderCard({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final cleanStatus = status.replaceAll('_', ' ');

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
                  title.trim().isEmpty ? 'Customer Order' : title.trim(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle.trim().isEmpty ? 'Customer' : subtitle.trim(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cleanStatus,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
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
