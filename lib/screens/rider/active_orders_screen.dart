import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart' show AppColors;
import '../../models/booking_model.dart' show BookingModel;
import '../../widgets/loading_widget.dart' show LoadingWidget;
import 'rider_task_details_screen.dart';

class ActiveOrdersScreen extends StatelessWidget {
  const ActiveOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'You need to sign in again.',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      );
    }

    final bookingsStream = FirebaseFirestore.instance
        .collection('bookings')
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F6),
      appBar: AppBar(
        title: const Text('Active Tasks'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: bookingsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading active tasks...');
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load active tasks.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final bookings =
              docs
                  .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
                  .where(
                    (booking) => _isActiveRiderTask(booking, currentUser.uid),
                  )
                  .toList()
                ..sort((a, b) {
                  final aTime = a.updatedAt ?? a.createdAt ?? DateTime(2000);
                  final bTime = b.updatedAt ?? b.createdAt ?? DateTime(2000);
                  return bTime.compareTo(aTime);
                });

          if (bookings.isEmpty) {
            return const _EmptyOrdersView();
          }

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final booking = bookings[index];

                return _ActiveTaskCard(
                  booking: booking,
                  onViewTask: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RiderTaskDetailsScreen(bookingId: booking.id),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  bool _isActiveRiderTask(BookingModel booking, String riderId) {
    final isPickupTask =
        booking.pickupRiderId == riderId &&
        (booking.status == 'pickup_started' ||
            booking.status == 'arrived_at_pickup' ||
            booking.status == 'picked_up' ||
            booking.status == 'arrived_at_laundry');

    final isDeliveryTask =
        booking.deliveryRiderId == riderId &&
        (booking.status == 'delivery_in_progress' ||
            booking.status == 'arrived_at_customer');

    return isPickupTask || isDeliveryTask;
  }
}

class _ActiveTaskCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onViewTask;

  const _ActiveTaskCard({required this.booking, required this.onViewTask});

  @override
  Widget build(BuildContext context) {
    final serviceType = booking.serviceType.replaceAll('_', ' ').toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.customerName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3440),
                  ),
                ),
              ),
              _StatusChip(status: booking.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            serviceType,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFF5B8A),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          _AddressRow(
            icon: Icons.location_on_outlined,
            title: 'Pickup:',
            value: booking.pickupAddress,
          ),
          const SizedBox(height: 10),
          _AddressRow(
            icon: Icons.outlined_flag_rounded,
            title: 'Dropoff:',
            value: booking.customerAddress,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onViewTask,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: const Color(0xFFFF5B8A),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'View Task',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _AddressRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: const Color(0xFF7B8492)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3440),
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7B8492),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final String text;

    switch (status) {
      case 'pickup_started':
      case 'delivery_in_progress':
        bg = const Color(0xFFE8F1FF);
        fg = const Color(0xFF3B82F6);
        text = 'active';
        break;
      case 'arrived_at_pickup':
      case 'arrived_at_customer':
      case 'arrived_at_laundry':
        bg = const Color(0xFFEDE9FE);
        fg = const Color(0xFF7C3AED);
        text = 'arrived';
        break;
      case 'picked_up':
        bg = const Color(0xFFE6F8EC);
        fg = const Color(0xFF2E9B57);
        text = 'picked up';
        break;
      default:
        bg = const Color(0xFFE8F1FF);
        fg = const Color(0xFF3B82F6);
        text = status.replaceAll('_', ' ');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
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
              Icons.local_shipping_outlined,
              size: 56,
              color: AppColors.iconMuted,
            ),
            SizedBox(height: 14),
            Text(
              'No active tasks',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Accepted rider tasks that are still in progress will show here.',
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
