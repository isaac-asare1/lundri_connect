import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/loading_widget.dart';

class RiderPaymentScreen extends StatelessWidget {
  const RiderPaymentScreen({super.key});

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

    return _RiderPaymentView(riderId: currentUser.uid);
  }
}

class _RiderPaymentView extends StatelessWidget {
  final String riderId;

  const _RiderPaymentView({required this.riderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F6),
      appBar: AppBar(
        title: const Text(
          'Payments',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: StreamBuilder<List<RiderEarningModel>>(
        stream: _streamRiderEarnings(riderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading payments...');
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load payments.\n${snapshot.error}',
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

          final earnings = snapshot.data ?? <RiderEarningModel>[];
          final summary = RiderPaymentSummary.fromEarnings(earnings);

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              children: [
                _RiderPaymentSummaryCard(summary: summary),
                const SizedBox(height: 14),
                _RiderPaymentBreakdownGrid(summary: summary),
                const SizedBox(height: 18),
                _RiderWithdrawalCard(summary: summary),
                const SizedBox(height: 22),
                const Text(
                  'Recent task earnings',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                if (earnings.isEmpty)
                  const _EmptyRiderPaymentsView()
                else
                  ...earnings.map(
                    (earning) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RiderEarningCard(earning: earning),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Stream<List<RiderEarningModel>> _streamRiderEarnings(String riderId) {
    return FirebaseFirestore.instance
        .collection('earnings_ledger')
        .where('userId', isEqualTo: riderId)
        .limit(100)
        .snapshots()
        .map((snapshot) {
          final earnings = snapshot.docs
              .map((doc) => RiderEarningModel.fromMap(doc.data(), doc.id))
              .where((earning) {
                final role = earning.role.trim().toLowerCase();
                return role == 'pickup_rider' ||
                    role == 'delivery_rider' ||
                    role == 'rider';
              })
              .toList();

          earnings.sort((a, b) {
            final aTime = a.displayTime ?? DateTime(2000);
            final bTime = b.displayTime ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });

          return earnings;
        });
  }
}

/* -------------------------------------------------------------------------- */
/*                              SUMMARY CARDS                                 */
/* -------------------------------------------------------------------------- */

class _RiderPaymentSummaryCard extends StatelessWidget {
  final RiderPaymentSummary summary;

  const _RiderPaymentSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.two_wheeler_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Available rider balance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${summary.currency} ${summary.availableAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your completed pickup and delivery task earnings will appear here.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.16)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Payouts can be sent to your MoMo or bank account when enabled.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 12.8,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
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

class _RiderPaymentBreakdownGrid extends StatelessWidget {
  final RiderPaymentSummary summary;

  const _RiderPaymentBreakdownGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniPaymentStatCard(
                title: 'Pending',
                value:
                    '${summary.currency} ${summary.pendingAmount.toStringAsFixed(2)}',
                icon: Icons.pending_actions_rounded,
                bgColor: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniPaymentStatCard(
                title: 'Paid out',
                value:
                    '${summary.currency} ${summary.paidOutAmount.toStringAsFixed(2)}',
                icon: Icons.verified_rounded,
                bgColor: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniPaymentStatCard(
                title: 'Pickup jobs',
                value: '${summary.pickupTaskCount}',
                icon: Icons.upload_rounded,
                bgColor: const Color(0xFFE9F9EF),
                iconColor: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniPaymentStatCard(
                title: 'Delivery jobs',
                value: '${summary.deliveryTaskCount}',
                icon: Icons.download_rounded,
                bgColor: const Color(0xFFFFEEF5),
                iconColor: const Color(0xFFFF5B8A),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MiniPaymentStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _MiniPaymentStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: bgColor,
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiderWithdrawalCard extends StatelessWidget {
  final RiderPaymentSummary summary;

  const _RiderWithdrawalCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final bool canWithdraw = summary.availableAmount > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: canWithdraw
                ? AppColors.primary.withOpacity(0.10)
                : const Color(0xFFF3F4F6),
            child: Icon(
              Icons.payments_outlined,
              color: canWithdraw ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request payout',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Withdraw your available rider balance.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.8,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: canWithdraw
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Payout request flow will be connected later.',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE5E7EB),
              disabledForegroundColor: AppColors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Withdraw',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                              EARNING CARD                                  */
/* -------------------------------------------------------------------------- */

class _RiderEarningCard extends StatelessWidget {
  final RiderEarningModel earning;

  const _RiderEarningCard({required this.earning});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(earning.status);
    final statusBg = statusColor.withOpacity(0.10);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: statusBg,
            child: Icon(
              earning.isPickupTask
                  ? Icons.upload_rounded
                  : Icons.download_rounded,
              color: statusColor,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  earning.readableTaskType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  earning.customerName.trim().isEmpty
                      ? earning.bookingLabel
                      : '${earning.customerName} • ${earning.bookingLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${earning.pickup} → ${earning.dropoff}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.4,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    earning.readableStatus,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${earning.currency} ${earning.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                _formatDate(earning.displayTime),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _statusColor(String status) {
    final clean = status.trim().toLowerCase();

    if (clean == 'available') return const Color(0xFF16A34A);
    if (clean == 'pending') return const Color(0xFFF59E0B);
    if (clean == 'paid_out') return const Color(0xFF2563EB);
    if (clean == 'reversed' || clean == 'cancelled') {
      return const Color(0xFFE53935);
    }

    return AppColors.primary;
  }

  static String _formatDate(DateTime? value) {
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

    return '${value.day} ${months[value.month - 1]}';
  }
}

class _EmptyRiderPaymentsView extends StatelessWidget {
  const _EmptyRiderPaymentsView();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 38, 24, 38),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 56,
            color: AppColors.iconMuted,
          ),
          SizedBox(height: 14),
          Text(
            'No rider earnings yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Completed pickup and delivery task earnings will appear here.',
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
    );
  }
}

/* -------------------------------------------------------------------------- */
/*                                  MODELS                                    */
/* -------------------------------------------------------------------------- */

class RiderEarningModel {
  final String id;
  final String bookingId;
  final String bookingCode;

  final String userId;
  final String role;
  final String taskType;

  final double amount;
  final String currency;
  final String status;

  final String customerName;
  final String pickup;
  final String dropoff;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? paidOutAt;

  const RiderEarningModel({
    required this.id,
    required this.bookingId,
    required this.bookingCode,
    required this.userId,
    required this.role,
    required this.taskType,
    required this.amount,
    required this.currency,
    required this.status,
    required this.customerName,
    required this.pickup,
    required this.dropoff,
    required this.createdAt,
    required this.updatedAt,
    required this.paidOutAt,
  });

  factory RiderEarningModel.fromMap(Map<String, dynamic> map, String docId) {
    return RiderEarningModel(
      id: docId,
      bookingId: _readString(map['bookingId']),
      bookingCode: _readString(map['bookingCode']),

      userId: _readString(map['userId']),
      role: _readString(map['role']),
      taskType: _readString(map['taskType']),

      amount: _readDouble(map['amount']),
      currency: _readString(map['currency'], fallback: 'GHS'),
      status: _readString(map['status'], fallback: 'pending'),

      customerName: _readString(map['customerName']),
      pickup: _readString(map['pickup'], fallback: 'Pickup'),
      dropoff: _readString(map['dropoff'], fallback: 'Drop-off'),

      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      paidOutAt: _parseTimestamp(map['paidOutAt']),
    );
  }

  bool get isPickupTask {
    final cleanTask = taskType.trim().toLowerCase();
    final cleanRole = role.trim().toLowerCase();

    return cleanTask == 'pickup' || cleanRole == 'pickup_rider';
  }

  bool get isDeliveryTask {
    final cleanTask = taskType.trim().toLowerCase();
    final cleanRole = role.trim().toLowerCase();

    return cleanTask == 'delivery' || cleanRole == 'delivery_rider';
  }

  String get readableTaskType {
    if (isPickupTask) return 'Pickup task';
    if (isDeliveryTask) return 'Delivery task';
    return 'Rider task';
  }

  String get readableStatus {
    if (status == 'paid_out') return 'Paid out';

    final clean = status.replaceAll('_', ' ').trim();
    if (clean.isEmpty) return 'Pending';

    return clean
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .map((word) {
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  String get bookingLabel {
    if (bookingCode.trim().isNotEmpty) {
      return 'Booking $bookingCode';
    }

    if (bookingId.trim().isNotEmpty) {
      return bookingId;
    }

    return 'Booking';
  }

  DateTime? get displayTime {
    return updatedAt ?? paidOutAt ?? createdAt;
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;

    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  static double _readDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class RiderPaymentSummary {
  final String currency;
  final double pendingAmount;
  final double availableAmount;
  final double paidOutAmount;
  final double reversedAmount;
  final int pickupTaskCount;
  final int deliveryTaskCount;

  const RiderPaymentSummary({
    required this.currency,
    required this.pendingAmount,
    required this.availableAmount,
    required this.paidOutAmount,
    required this.reversedAmount,
    required this.pickupTaskCount,
    required this.deliveryTaskCount,
  });

  factory RiderPaymentSummary.fromEarnings(List<RiderEarningModel> earnings) {
    double pending = 0;
    double available = 0;
    double paidOut = 0;
    double reversed = 0;

    int pickupTasks = 0;
    int deliveryTasks = 0;

    String currency = 'GHS';

    for (final earning in earnings) {
      currency = earning.currency.isEmpty ? currency : earning.currency;

      if (earning.isPickupTask) pickupTasks++;
      if (earning.isDeliveryTask) deliveryTasks++;

      switch (earning.status.trim().toLowerCase()) {
        case 'available':
          available += earning.amount;
          break;
        case 'paid_out':
          paidOut += earning.amount;
          break;
        case 'reversed':
        case 'cancelled':
          reversed += earning.amount;
          break;
        case 'pending':
        default:
          pending += earning.amount;
          break;
      }
    }

    return RiderPaymentSummary(
      currency: currency,
      pendingAmount: pending,
      availableAmount: available,
      paidOutAmount: paidOut,
      reversedAmount: reversed,
      pickupTaskCount: pickupTasks,
      deliveryTaskCount: deliveryTasks,
    );
  }
}
