import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';
import '../../widgets/loading_widget.dart';
import '../laundry/laundry_history_details_screen.dart';

class RidersOdersHistoryScreen extends StatelessWidget {
  const RidersOdersHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OrdersHistoryScreen(role: 'rider');
  }
}

class LaundriesOrdersHistoryScreen extends StatelessWidget {
  const LaundriesOrdersHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const OrdersHistoryScreen(role: 'laundry');
  }
}

class OrdersHistoryScreen extends StatelessWidget {
  final String role;

  const OrdersHistoryScreen({super.key, required this.role});

  bool get isRider => role == 'rider';

  static const String riderHistoryAmount = 'GHS 10';

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

    if (isRider) {
      return _RiderHistoryView(riderId: currentUser.uid);
    }

    return _LaundryHistoryView(laundryId: currentUser.uid);
  }
}

class _RiderHistoryView extends StatelessWidget {
  final String riderId;

  const _RiderHistoryView({required this.riderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F6),
      appBar: AppBar(
        title: const Text('Orders History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: StreamBuilder<List<CompletedRideModel>>(
        stream: _streamCompletedRides(riderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading history...');
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load history.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }

          final rides = snapshot.data ?? <CompletedRideModel>[];

          if (rides.isEmpty) {
            return const _EmptyHistoryView();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: rides.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final ride = rides[index];

              return _CompletedRideHistoryCard(
                ride: ride,
                amountText: OrdersHistoryScreen.riderHistoryAmount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CompletedRideHistoryDetailsScreen(
                        ride: ride,
                        amountText: OrdersHistoryScreen.riderHistoryAmount,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static Stream<List<CompletedRideModel>> _streamCompletedRides(
    String riderId,
  ) {
    return FirebaseFirestore.instance
        .collection('completed_rides')
        .where('riderId', isEqualTo: riderId)
        .orderBy('completedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final rides = snapshot.docs
              .map((doc) => CompletedRideModel.fromMap(doc.data(), doc.id))
              .toList();

          rides.sort((a, b) {
            final aTime = a.completedAt ?? DateTime(2000);
            final bTime = b.completedAt ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });

          return rides;
        });
  }
}

class _LaundryHistoryView extends StatelessWidget {
  final String laundryId;

  const _LaundryHistoryView({required this.laundryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F6),
      appBar: AppBar(
        title: const Text('Orders History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: _streamLaundryHistory(laundryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading history...');
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load history.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }

          final bookings = snapshot.data ?? <BookingModel>[];

          if (bookings.isEmpty) {
            return const _EmptyHistoryView();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final booking = bookings[index];

              return _LaundryHistoryBookingCard(
                booking: booking,
                userId: laundryId,
                role: 'laundry',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingHistoryDetailsScreen(
                        booking: booking,
                        role: 'laundry',
                        userId: laundryId,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static Stream<List<BookingModel>> _streamLaundryHistory(String laundryId) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('status', whereIn: ['complete', 'completed'])
        .where('laundrySnapshot.id', isEqualTo: laundryId)
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList();

          bookings.sort((a, b) {
            final aTime =
                a.updatedAt ?? a.requestedAt ?? a.createdAt ?? DateTime(2000);
            final bTime =
                b.updatedAt ?? b.requestedAt ?? b.createdAt ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });

          return bookings;
        });
  }
}

class CompletedRideModel {
  final String id;
  final String bookingId;
  final String riderId;
  final String role;
  final String pickup;
  final String dropoff;
  final String customerId;
  final String customerName;
  final DateTime? completedAt;

  const CompletedRideModel({
    required this.id,
    required this.bookingId,
    required this.riderId,
    required this.role,
    required this.pickup,
    required this.dropoff,
    required this.customerId,
    required this.customerName,
    required this.completedAt,
  });

  factory CompletedRideModel.fromMap(Map<String, dynamic> map, String docId) {
    return CompletedRideModel(
      id: docId,
      bookingId: _readString(map['bookingId']),
      riderId: _readString(map['riderId']),
      role: _readString(map['role']),
      pickup: _readString(map['pickup'], fallback: 'Pickup not available'),
      dropoff: _readString(map['dropoff'], fallback: 'Drop-off not available'),
      customerId: _readString(map['customerId']),
      customerName: _readString(map['customerName'], fallback: 'Customer'),
      completedAt: _parseTimestamp(map['completedAt']),
    );
  }

  bool get isPickupRide => role == 'pickup_rider';

  String get readableRole {
    if (role == 'pickup_rider') return 'Pickup rider';
    if (role == 'delivery_rider') return 'Delivery rider';
    return role.replaceAll('_', ' ');
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;

    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class _CompletedRideHistoryCard extends StatelessWidget {
  final CompletedRideModel ride;
  final String amountText;
  final VoidCallback onTap;

  const _CompletedRideHistoryCard({
    required this.ride,
    required this.amountText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pickup = ride.pickup.trim().isEmpty ? 'Pickup' : ride.pickup.trim();
    final dropoff = ride.dropoff.trim().isEmpty
        ? 'Drop-off'
        : ride.dropoff.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 21,
                backgroundColor: Color(0xFFE9F9EF),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF3FC37A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$pickup - $dropoff',
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatTime(ride.completedAt),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime? value) {
    if (value == null) return '—';

    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

class _LaundryHistoryBookingCard extends StatelessWidget {
  final BookingModel booking;
  final String userId;
  final String role;
  final VoidCallback onTap;

  const _LaundryHistoryBookingCard({
    required this.booking,
    required this.userId,
    required this.role,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime? time =
        booking.updatedAt ?? booking.requestedAt ?? booking.createdAt;

    final pickup = booking.pickupAddress.trim().isEmpty
        ? 'Pickup'
        : booking.pickupAddress.trim();

    final dropoff = booking.customerAddress.trim().isEmpty
        ? 'Drop-off'
        : booking.customerAddress.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 21,
                backgroundColor: Color(0xFFE9F9EF),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF3FC37A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$pickup - $dropoff',
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'GHS ${booking.totalPrice}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _formatTime(time),
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(DateTime? value) {
    if (value == null) return '—';

    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }
}

class CompletedRideHistoryDetailsScreen extends StatelessWidget {
  final CompletedRideModel ride;
  final String amountText;

  const CompletedRideHistoryDetailsScreen({
    super.key,
    required this.ride,
    required this.amountText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F6),
      appBar: AppBar(
        title: const Text('Ride Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _DetailsHeaderCard(
            title: ride.customerName,
            subtitle: ride.readableRole,
            amount: amountText,
          ),
          const SizedBox(height: 14),
          _DetailsSection(
            title: 'Route',
            children: [
              _DetailsRow(
                icon: Icons.location_on_outlined,
                label: 'Pickup',
                value: ride.pickup,
              ),
              _DetailsRow(
                icon: Icons.outlined_flag_rounded,
                label: 'Drop-off',
                value: ride.dropoff,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DetailsSection(
            title: 'Ride',
            children: [
              _DetailsRow(
                icon: Icons.person_outline_rounded,
                label: 'Customer',
                value: ride.customerName,
              ),
              _DetailsRow(
                icon: Icons.assignment_outlined,
                label: 'Booking ID',
                value: ride.bookingId,
              ),
              _DetailsRow(
                icon: Icons.delivery_dining_rounded,
                label: 'Role',
                value: ride.readableRole,
              ),
              _DetailsRow(
                icon: Icons.access_time_rounded,
                label: 'Completed',
                value: _formatFullDateTime(ride.completedAt),
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
  final String subtitle;
  final String amount;

  const _DetailsHeaderCard({
    required this.title,
    required this.subtitle,
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
                  title.trim().isEmpty ? 'Customer' : title.trim(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle.trim().isEmpty ? 'Completed ride' : subtitle.trim(),
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

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 58, color: AppColors.iconMuted),
            SizedBox(height: 14),
            Text(
              'No completed rides yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Completed pickup and delivery rides will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
