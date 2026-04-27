import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';
import '../../widgets/loading_widget.dart';
import 'booking_history_details_screen.dart';

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

    final historyStream = isRider
        ? _streamRiderHistory(currentUser.uid)
        : _streamLaundryHistory(currentUser.uid);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F6),
      appBar: AppBar(
        title: const Text('Orders History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: StreamBuilder<List<BookingModel>>(
        stream: historyStream,
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

              return _HistoryBookingCard(
                booking: booking,
                userId: currentUser.uid,
                role: role,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BookingHistoryDetailsScreen(
                        booking: booking,
                        role: role,
                        userId: currentUser.uid,
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

  static Stream<List<BookingModel>> _streamRiderHistory(String riderId) {
    final pickupStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('status', whereIn: ['arrived_at_laundry'])
        .where('pickupRider.riderId', isEqualTo: riderId)
        .orderBy('updatedAt', descending: true)
        .limit(30)
        .snapshots();

    final deliveryStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('status', whereIn: ['completed'])
        .where('deliveryRider.riderId', isEqualTo: riderId)
        .orderBy('updatedAt', descending: true)
        .limit(30)
        .snapshots();

    return _mergeBookingStreams([pickupStream, deliveryStream]);
  }

  static Stream<List<BookingModel>> _streamLaundryHistory(String laundryId) {
    final laundryStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('status', whereIn: ['complete', 'completed'])
        .where('laundrySnapshot.id', isEqualTo: laundryId)
        .orderBy('updatedAt', descending: true)
        .limit(50)
        .snapshots();

    return laundryStream.map((snapshot) {
      final bookings = snapshot.docs
          .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
          .toList();

      bookings.sort(_sortNewestFirst);
      return bookings;
    });
  }

  static Stream<List<BookingModel>> _mergeBookingStreams(
    List<Stream<QuerySnapshot<Map<String, dynamic>>>> streams,
  ) {
    final controller = StreamController<List<BookingModel>>();

    final Map<int, QuerySnapshot<Map<String, dynamic>>> latestSnapshots = {};
    final List<StreamSubscription> subscriptions = [];

    void emit() {
      final Map<String, BookingModel> merged = {};

      for (final snapshot in latestSnapshots.values) {
        for (final doc in snapshot.docs) {
          merged[doc.id] = BookingModel.fromMap(doc.data(), doc.id);
        }
      }

      final bookings = merged.values.toList()..sort(_sortNewestFirst);

      if (!controller.isClosed) {
        controller.add(bookings);
      }
    }

    for (int i = 0; i < streams.length; i++) {
      final sub = streams[i].listen((snapshot) {
        latestSnapshots[i] = snapshot;
        emit();
      }, onError: controller.addError);

      subscriptions.add(sub);
    }

    controller.onCancel = () async {
      for (final sub in subscriptions) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }

  static int _sortNewestFirst(BookingModel a, BookingModel b) {
    final aTime = a.updatedAt ?? a.requestedAt ?? a.createdAt ?? DateTime(2000);
    final bTime = b.updatedAt ?? b.requestedAt ?? b.createdAt ?? DateTime(2000);
    return bTime.compareTo(aTime);
  }
}

class _HistoryBookingCard extends StatelessWidget {
  final BookingModel booking;
  final String userId;
  final String role;
  final VoidCallback onTap;

  const _HistoryBookingCard({
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

    // final pickup = booking.status == "arrived" ? booking.pickupAddress

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
                children: [
                  Text(
                    'GHS ${booking.totalPrice}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),

                  SizedBox(height: 10),
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
              'No completed orders yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Completed pickup and delivery tasks will appear here.',
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
