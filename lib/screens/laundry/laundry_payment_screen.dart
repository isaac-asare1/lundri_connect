import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/loading_widget.dart';

class LaundryPaymentScreen extends StatelessWidget {
  const LaundryPaymentScreen({super.key});

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

    return _LaundryPaymentView(laundryId: currentUser.uid);
  }
}

class _LaundryPaymentView extends StatelessWidget {
  final String laundryId;

  const _LaundryPaymentView({required this.laundryId});

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
      body: StreamBuilder<List<LaundryEarningModel>>(
        stream: _streamLaundryEarnings(laundryId),
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

          final earnings = snapshot.data ?? <LaundryEarningModel>[];

          final summary = LaundryPaymentSummary.fromEarnings(earnings);

          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
              children: [
                _PaymentSummaryCard(summary: summary),
                const SizedBox(height: 14),
                _PaymentBreakdownGrid(summary: summary),
                const SizedBox(height: 18),
                _WithdrawalCard(summary: summary),
                const SizedBox(height: 22),
                const Text(
                  'Recent earnings',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                if (earnings.isEmpty)
                  const _EmptyPaymentsView()
                else
                  ...earnings.map(
                    (earning) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _LaundryEarningCard(earning: earning),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Stream<List<LaundryEarningModel>> _streamLaundryEarnings(
    String laundryId,
  ) {
    return FirebaseFirestore.instance
        .collection('earnings_ledger')
        .where('userId', isEqualTo: laundryId)
        .where('role', isEqualTo: 'laundry')
        .limit(80)
        .snapshots()
        .map((snapshot) {
          final earnings = snapshot.docs
              .map((doc) => LaundryEarningModel.fromMap(doc.data(), doc.id))
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

class _PaymentSummaryCard extends StatelessWidget {
  final LaundryPaymentSummary summary;

  const _PaymentSummaryCard({required this.summary});

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
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Available balance',
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
            'Ready for payout after completed bookings are cleared.',
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
                    'Payouts can be sent through your preferred Paystack payout method when enabled.',
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

class _PaymentBreakdownGrid extends StatelessWidget {
  final LaundryPaymentSummary summary;

  const _PaymentBreakdownGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
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

class _WithdrawalCard extends StatelessWidget {
  final LaundryPaymentSummary summary;

  const _WithdrawalCard({required this.summary});

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
                  'Withdraw available balance to your MoMo or bank account.',
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

class _LaundryEarningCard extends StatelessWidget {
  final LaundryEarningModel earning;

  const _LaundryEarningCard({required this.earning});

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
              _statusIcon(earning.status),
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
                  earning.customerName.isEmpty
                      ? 'Laundry earning'
                      : earning.customerName,
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
                  earning.bookingCode.isEmpty
                      ? earning.bookingId
                      : 'Booking ${earning.bookingCode}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 7),
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

  static IconData _statusIcon(String status) {
    final clean = status.trim().toLowerCase();

    if (clean == 'available') return Icons.check_circle_rounded;
    if (clean == 'pending') return Icons.pending_actions_rounded;
    if (clean == 'paid_out') return Icons.verified_rounded;
    if (clean == 'reversed' || clean == 'cancelled') {
      return Icons.cancel_rounded;
    }

    return Icons.account_balance_wallet_outlined;
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

class _EmptyPaymentsView extends StatelessWidget {
  const _EmptyPaymentsView();

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
            'No earnings yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Completed laundry orders will appear here once earnings are recorded.',
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

class LaundryEarningModel {
  final String id;
  final String bookingId;
  final String bookingCode;
  final String userId;
  final String role;
  final double amount;
  final String currency;
  final String status;
  final String customerName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? paidOutAt;

  const LaundryEarningModel({
    required this.id,
    required this.bookingId,
    required this.bookingCode,
    required this.userId,
    required this.role,
    required this.amount,
    required this.currency,
    required this.status,
    required this.customerName,
    required this.createdAt,
    required this.updatedAt,
    required this.paidOutAt,
  });

  factory LaundryEarningModel.fromMap(Map<String, dynamic> map, String docId) {
    return LaundryEarningModel(
      id: docId,
      bookingId: _readString(map['bookingId']),
      bookingCode: _readString(map['bookingCode']),
      userId: _readString(map['userId']),
      role: _readString(map['role']),
      amount: _readDouble(map['amount']),
      currency: _readString(map['currency'], fallback: 'GHS'),
      status: _readString(map['status'], fallback: 'pending'),
      customerName: _readString(map['customerName']),
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      paidOutAt: _parseTimestamp(map['paidOutAt']),
    );
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

class LaundryPaymentSummary {
  final String currency;
  final double pendingAmount;
  final double availableAmount;
  final double paidOutAmount;
  final double reversedAmount;

  const LaundryPaymentSummary({
    required this.currency,
    required this.pendingAmount,
    required this.availableAmount,
    required this.paidOutAmount,
    required this.reversedAmount,
  });

  factory LaundryPaymentSummary.fromEarnings(
    List<LaundryEarningModel> earnings,
  ) {
    double pending = 0;
    double available = 0;
    double paidOut = 0;
    double reversed = 0;

    String currency = 'GHS';

    for (final earning in earnings) {
      currency = earning.currency.isEmpty ? currency : earning.currency;

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

    return LaundryPaymentSummary(
      currency: currency,
      pendingAmount: pending,
      availableAmount: available,
      paidOutAmount: paidOut,
      reversedAmount: reversed,
    );
  }
}
