import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/loading_widget.dart';

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

/* -------------------------------------------------------------------------- */
/*                               RIDER HISTORY                                */
/* -------------------------------------------------------------------------- */

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
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final rides = snapshot.docs
              .map((doc) => CompletedRideModel.fromMap(doc.data(), doc.id))
              .toList();

          rides.sort((a, b) {
            final aTime = a.displayTime ?? DateTime(2000);
            final bTime = b.displayTime ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });

          return rides;
        });
  }
}

/* -------------------------------------------------------------------------- */
/*                              LAUNDRY HISTORY                               */
/* -------------------------------------------------------------------------- */

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
      body: StreamBuilder<List<LaundryOrderHistoryModel>>(
        stream: _streamLaundryOrderHistory(laundryId),
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

          final histories = snapshot.data ?? <LaundryOrderHistoryModel>[];

          if (histories.isEmpty) {
            return const _EmptyHistoryView(
              title: 'No laundry history yet',
              subtitle:
                  'Completed, cancelled, and rejected laundry orders will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: histories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final history = histories[index];

              return _LaundryOrderHistoryCard(
                history: history,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          LaundryOrderHistoryDetailsScreen(history: history),
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

  static Stream<List<LaundryOrderHistoryModel>> _streamLaundryOrderHistory(
    String laundryId,
  ) {
    return FirebaseFirestore.instance
        .collection('laundry_order_history')
        .where('laundryId', isEqualTo: laundryId)
        .limit(50)
        .snapshots()
        .map((snapshot) {
          final histories = snapshot.docs
              .map(
                (doc) => LaundryOrderHistoryModel.fromMap(doc.data(), doc.id),
              )
              .toList();

          histories.sort((a, b) {
            final aTime = a.displayTime ?? DateTime(2000);
            final bTime = b.displayTime ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });

          return histories;
        });
  }
}

/* -------------------------------------------------------------------------- */
/*                                  MODELS                                    */
/* -------------------------------------------------------------------------- */

class CompletedRideModel {
  final String id;
  final String bookingId;
  final String bookingCode;

  final String riderId;
  final String role;
  final String taskType;
  final String status;

  final String pickup;
  final String dropoff;

  final String customerId;
  final String customerName;
  final String customerPhone;

  final String laundryId;
  final String laundryName;
  final String laundryPhone;

  final String cancellationReason;
  final String cancellationNote;

  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CompletedRideModel({
    required this.id,
    required this.bookingId,
    required this.bookingCode,
    required this.riderId,
    required this.role,
    required this.taskType,
    required this.status,
    required this.pickup,
    required this.dropoff,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.laundryId,
    required this.laundryName,
    required this.laundryPhone,
    required this.cancellationReason,
    required this.cancellationNote,
    required this.completedAt,
    required this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompletedRideModel.fromMap(Map<String, dynamic> map, String docId) {
    final cancellation = _asMap(map['cancellation']);

    return CompletedRideModel(
      id: docId,
      bookingId: _readString(map['bookingId']),
      bookingCode: _readString(map['bookingCode']),

      riderId: _readString(map['riderId']),
      role: _readString(map['role']),
      taskType: _readString(map['taskType']),
      status: _readString(map['status']),

      pickup: _readString(map['pickup'], fallback: 'Pickup not available'),
      dropoff: _readString(map['dropoff'], fallback: 'Drop-off not available'),

      customerId: _readString(map['customerId']),
      customerName: _readString(map['customerName'], fallback: 'Customer'),
      customerPhone: _readString(map['customerPhone']),

      laundryId: _readString(map['laundryId']),
      laundryName: _readString(map['laundryName'], fallback: 'Laundry'),
      laundryPhone: _readString(map['laundryPhone']),

      cancellationReason: _readString(cancellation['reason']),
      cancellationNote: _readString(cancellation['note']),

      completedAt: _parseTimestamp(map['completedAt']),
      cancelledAt: _parseTimestamp(map['cancelledAt']),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  bool get isPickupRide => role == 'pickup_rider';

  bool get isCancelled => status == 'cancelled';

  String get readableRole {
    if (role == 'pickup_rider') return 'Pickup rider';
    if (role == 'delivery_rider') return 'Delivery rider';
    return role.replaceAll('_', ' ');
  }

  DateTime? get displayTime {
    return updatedAt ?? completedAt ?? cancelledAt ?? createdAt;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;

    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }

    return <String, dynamic>{};
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

class LaundryOrderHistoryModel {
  final String id;
  final String bookingId;
  final String bookingCode;

  final String laundryId;
  final String laundryName;
  final String laundryPhone;

  final String customerId;
  final String customerName;
  final String customerPhone;

  final String serviceType;
  final List<String> selectedAddOns;

  final int estimatedWeightKg;
  final int? actualWeightKg;

  final String pickupAddress;
  final String dropoffAddress;

  final int totalPrice;
  final String currency;

  final String status;

  final String rejectionReason;
  final String rejectionNote;

  final DateTime? rejectedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LaundryOrderHistoryModel({
    required this.id,
    required this.bookingId,
    required this.bookingCode,
    required this.laundryId,
    required this.laundryName,
    required this.laundryPhone,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.serviceType,
    required this.selectedAddOns,
    required this.estimatedWeightKg,
    required this.actualWeightKg,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.totalPrice,
    required this.currency,
    required this.status,
    required this.rejectionReason,
    required this.rejectionNote,
    required this.rejectedAt,
    required this.completedAt,
    required this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LaundryOrderHistoryModel.fromMap(
    Map<String, dynamic> map,
    String docId,
  ) {
    final rejection = _asMap(map['rejection']);

    return LaundryOrderHistoryModel(
      id: docId,
      bookingId: _readString(map['bookingId']),
      bookingCode: _readString(map['bookingCode']),

      laundryId: _readString(map['laundryId']),
      laundryName: _readString(map['laundryName'], fallback: 'Laundry'),
      laundryPhone: _readString(map['laundryPhone']),

      customerId: _readString(map['customerId']),
      customerName: _readString(map['customerName'], fallback: 'Customer'),
      customerPhone: _readString(map['customerPhone']),

      serviceType: _readString(map['serviceType']),
      selectedAddOns: _readStringList(map['selectedAddOns']),

      estimatedWeightKg: _readInt(map['estimatedWeightKg']),
      actualWeightKg: _readNullableInt(map['actualWeightKg']),

      pickupAddress: _readString(
        map['pickupAddress'],
        fallback: 'Pickup address not available',
      ),
      dropoffAddress: _readString(
        map['dropoffAddress'],
        fallback: 'Drop-off address not available',
      ),

      totalPrice: _readInt(map['totalPrice']),
      currency: _readString(map['currency'], fallback: 'GHS'),

      status: _readString(map['status'], fallback: 'completed'),

      rejectionReason: _readString(rejection['reason']),
      rejectionNote: _readString(rejection['note']),

      rejectedAt: _parseTimestamp(map['rejectedAt']),
      completedAt: _parseTimestamp(map['completedAt']),
      cancelledAt: _parseTimestamp(map['cancelledAt']),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
    );
  }

  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed' || status == 'complete';

  String get readableStatus {
    if (isRejected) return 'Rejected';
    if (isCancelled) return 'Cancelled';
    if (isCompleted) return 'Completed';
    return status.replaceAll('_', ' ');
  }

  String get readableServiceType {
    if (serviceType == 'wash_fold') return 'Wash & Fold';
    if (serviceType == 'wash_iron') return 'Wash & Iron';

    final clean = serviceType.replaceAll('_', ' ').trim();
    return clean.isEmpty ? 'Service' : clean;
  }

  DateTime? get displayTime {
    return updatedAt ?? rejectedAt ?? completedAt ?? cancelledAt ?? createdAt;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;

    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }

    return <String, dynamic>{};
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;

    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    return <String>[];
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/* -------------------------------------------------------------------------- */
/*                              RIDER CARD UI                                 */
/* -------------------------------------------------------------------------- */

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ride.isCancelled
                  ? const CircleAvatar(
                      radius: 21,
                      backgroundColor: Color(0xFFFFEAEA),
                      child: Icon(
                        Icons.cancel_rounded,
                        color: Color(0xFFE53935),
                        size: 24,
                      ),
                    )
                  : const CircleAvatar(
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
                    _formatTime(ride.displayTime),
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

/* -------------------------------------------------------------------------- */
/*                             LAUNDRY CARD UI                                */
/* -------------------------------------------------------------------------- */

class _LaundryOrderHistoryCard extends StatelessWidget {
  final LaundryOrderHistoryModel history;
  final VoidCallback onTap;

  const _LaundryOrderHistoryCard({required this.history, required this.onTap});

  Color get _iconBg {
    if (history.isRejected || history.isCancelled) {
      return const Color(0xFFFFEAEA);
    }

    return const Color(0xFFE9F9EF);
  }

  Color get _iconColor {
    if (history.isRejected || history.isCancelled) {
      return const Color(0xFFE53935);
    }

    return const Color(0xFF3FC37A);
  }

  IconData get _icon {
    if (history.isRejected) return Icons.block_rounded;
    if (history.isCancelled) return Icons.cancel_rounded;
    return Icons.check_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final DateTime? time = history.displayTime;

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: _iconBg,
                child: Icon(_icon, color: _iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      history.customerName,
                      softWrap: true,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      history.readableServiceType,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      history.readableStatus,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _iconColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${history.currency} ${history.totalPrice}',
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

/* -------------------------------------------------------------------------- */
/*                              RIDER DETAILS                                 */
/* -------------------------------------------------------------------------- */

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
    final statusText = ride.isCancelled ? 'Cancelled ride' : 'Completed ride';

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
            subtitle: statusText,
            amount: amountText,
            isNegative: ride.isCancelled,
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
                icon: Icons.phone_outlined,
                label: 'Customer phone',
                value: ride.customerPhone,
              ),
              _DetailsRow(
                icon: Icons.delivery_dining_rounded,
                label: 'Role',
                value: ride.readableRole,
              ),
              _DetailsRow(
                icon: Icons.info_outline_rounded,
                label: 'Status',
                value: ride.status,
              ),
              _DetailsRow(
                icon: Icons.access_time_rounded,
                label: ride.isCancelled ? 'Cancelled' : 'Completed',
                value: _formatFullDateTime(
                  ride.isCancelled ? ride.cancelledAt : ride.completedAt,
                ),
              ),
            ],
          ),
          if (ride.isCancelled) ...[
            const SizedBox(height: 14),
            _DetailsSection(
              title: 'Cancellation',
              children: [
                _DetailsRow(
                  icon: Icons.block_rounded,
                  label: 'Reason',
                  value: ride.cancellationReason,
                ),
                _DetailsRow(
                  icon: Icons.notes_rounded,
                  label: 'Note',
                  value: ride.cancellationNote,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                             LAUNDRY DETAILS                                */
/* -------------------------------------------------------------------------- */

class LaundryOrderHistoryDetailsScreen extends StatelessWidget {
  final LaundryOrderHistoryModel history;

  const LaundryOrderHistoryDetailsScreen({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
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
            title: history.customerName,
            subtitle: history.readableStatus,
            amount: '${history.currency} ${history.totalPrice}',
            isNegative: history.isRejected || history.isCancelled,
          ),
          const SizedBox(height: 14),
          _DetailsSection(
            title: 'Customer',
            children: [
              _DetailsRow(
                icon: Icons.person_outline_rounded,
                label: 'Name',
                value: history.customerName,
              ),
              _DetailsRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: history.customerPhone,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DetailsSection(
            title: 'Order',
            children: [
              _DetailsRow(
                icon: Icons.receipt_long_outlined,
                label: 'Booking code',
                value: history.bookingCode,
              ),
              _DetailsRow(
                icon: Icons.local_laundry_service_outlined,
                label: 'Service',
                value: history.readableServiceType,
              ),
              _DetailsRow(
                icon: Icons.scale_outlined,
                label: 'Estimated weight',
                value: '${history.estimatedWeightKg} kg',
              ),
              _DetailsRow(
                icon: Icons.monitor_weight_outlined,
                label: 'Actual weight',
                value: history.actualWeightKg == null
                    ? '—'
                    : '${history.actualWeightKg} kg',
              ),
              _DetailsRow(
                icon: Icons.payments_outlined,
                label: 'Amount',
                value: '${history.currency} ${history.totalPrice}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DetailsSection(
            title: 'Addresses',
            children: [
              _DetailsRow(
                icon: Icons.location_on_outlined,
                label: 'Pickup',
                value: history.pickupAddress,
              ),
              _DetailsRow(
                icon: Icons.outlined_flag_rounded,
                label: 'Drop-off',
                value: history.dropoffAddress,
              ),
            ],
          ),
          if (history.isRejected) ...[
            const SizedBox(height: 14),
            _DetailsSection(
              title: 'Rejection',
              children: [
                _DetailsRow(
                  icon: Icons.block_rounded,
                  label: 'Reason',
                  value: history.rejectionReason,
                ),
                _DetailsRow(
                  icon: Icons.notes_rounded,
                  label: 'Note',
                  value: history.rejectionNote,
                ),
                _DetailsRow(
                  icon: Icons.access_time_rounded,
                  label: 'Rejected at',
                  value: _formatFullDateTime(history.rejectedAt),
                ),
              ],
            ),
          ],
          if (history.isCancelled) ...[
            const SizedBox(height: 14),
            _DetailsSection(
              title: 'Cancellation',
              children: [
                _DetailsRow(
                  icon: Icons.cancel_rounded,
                  label: 'Cancelled at',
                  value: _formatFullDateTime(history.cancelledAt),
                ),
              ],
            ),
          ],
          if (history.isCompleted) ...[
            const SizedBox(height: 14),
            _DetailsSection(
              title: 'Completion',
              children: [
                _DetailsRow(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Completed at',
                  value: _formatFullDateTime(history.completedAt),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          _DetailsSection(
            title: 'Timeline',
            children: [
              _DetailsRow(
                icon: Icons.access_time_rounded,
                label: 'Created',
                value: _formatFullDateTime(history.createdAt),
              ),
              _DetailsRow(
                icon: Icons.update_rounded,
                label: 'Last updated',
                value: _formatFullDateTime(history.updatedAt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              SHARED DETAILS                                */
/* -------------------------------------------------------------------------- */

class _DetailsHeaderCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;
  final bool isNegative;

  const _DetailsHeaderCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = isNegative
        ? const Color(0xFFFFEAEA)
        : const Color(0xFFE9F9EF);

    final iconColor = isNegative
        ? const Color(0xFFE53935)
        : const Color(0xFF3FC37A);

    final icon = isNegative ? Icons.cancel_rounded : Icons.receipt_long_rounded;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: iconBg,
            child: Icon(icon, color: iconColor, size: 28),
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
                  subtitle.trim().isEmpty ? 'Order history' : subtitle.trim(),
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
  final String title;
  final String subtitle;

  const _EmptyHistoryView({
    this.title = 'No completed rides yet',
    this.subtitle = 'Completed pickup and delivery rides will appear here.',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 58,
              color: AppColors.iconMuted,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
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

/* -------------------------------------------------------------------------- */
/*                                DATE HELPERS                                */
/* -------------------------------------------------------------------------- */

String _formatFullDateTime(DateTime? value) {
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
