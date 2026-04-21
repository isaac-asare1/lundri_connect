import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lundri_connect/screens/active_orders_screen.dart';
import 'package:lundri_connect/screens/payments_screen.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/loading_widget.dart';
import 'requests_screen.dart';

class OperatorHomeScreen extends StatefulWidget {
  const OperatorHomeScreen({super.key});

  @override
  State<OperatorHomeScreen> createState() => _OperatorHomeScreenState();
}

class _OperatorHomeScreenState extends State<OperatorHomeScreen> {
  final BookingService _bookingService = BookingService();

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<UserProvider>().loadCurrentUser();
    });
  }

  Future<void> _refreshDashboard() async {
    await context.read<UserProvider>().loadCurrentUser();
  }

  bool _isRequestStatus(String status) {
    final normalized = status.trim().toLowerCase();

    const requestStatuses = {
      'pending',
      'requested',
      'awaiting_laundry_acceptance',
      'offered_to_laundry',
    };

    return requestStatuses.contains(normalized);
  }

  bool _isActiveStatus(String status) {
    final normalized = status.trim().toLowerCase();

    const nonActiveStatuses = {
      'looking_for_pickup_rider',
      'pickup_rider_assigned',
      'pickup_started',
      'picked_up',
      'arrived_at_laundry',
      'processing',
      'ready_for_dropoff',
      'delivery_rider_assigned',
      'delivery_started',
      'delivery_in_progress',
    };

    return nonActiveStatuses.contains(normalized);
  }

  bool _isPendingPayment(String paymentStatus) {
    final normalized = paymentStatus.trim().toLowerCase();
    return normalized == 'unpaid' || normalized == 'pending';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<UserProvider, bool>(
      (provider) => provider.isLoading,
    );

    final laundryId = context.select<UserProvider, String>(
      (provider) => provider.currentUser?.id ?? '',
    );

    final operatorName = context.select<UserProvider, String>(
      (provider) => provider.currentUser?.fullName ?? 'Operator',
    );

    final businessName = context.select<UserProvider, String>(
      (provider) => provider.businessInfo?.businessName ?? 'Lundri Business',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: isLoading
            ? const LoadingWidget(message: 'Loading dashboard...')
            : laundryId.isEmpty
            ? const Center(
                child: Text(
                  'Operator account not found.',
                  style: TextStyle(fontSize: 15),
                ),
              )
            : StreamBuilder<List<BookingModel>>(
                stream: _bookingService.streamOperatorBookings(laundryId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget(message: 'Loading dashboard...');
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Failed to load bookings.\n${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final bookings = snapshot.data ?? [];

                  final pendingRequests = bookings
                      .where((b) => _isRequestStatus(b.status))
                      .length;

                  final activeOrdersCount = bookings
                      .where((b) => _isActiveStatus(b.status))
                      .length;

                  final pendingPayments = bookings
                      .where((b) => _isPendingPayment(b.paymentStatus))
                      .length;

                  return RefreshIndicator(
                    onRefresh: _refreshDashboard,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _ModernHeaderCard(
                                  operatorName: operatorName,
                                  businessName: businessName,
                                ),
                                const SizedBox(height: 18),
                                const _OnlineStatusSection(),
                                const SizedBox(height: 20),
                                const Text(
                                  'Overview',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GridView.count(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.12,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                    _ModernStatCard(
                                      title: 'Requests',
                                      value: '$pendingRequests',
                                      subtitle: 'Incoming bookings',
                                      icon: Icons.inbox_rounded,
                                    ),
                                    _ModernStatCard(
                                      title: 'Orders',
                                      value: '$activeOrdersCount',
                                      subtitle: 'Currently active',
                                      icon: Icons.local_laundry_service_rounded,
                                    ),
                                    _ModernStatCard(
                                      title: 'Payments',
                                      value: '$pendingPayments',
                                      subtitle: 'Pending clearance',
                                      icon:
                                          Icons.account_balance_wallet_rounded,
                                    ),
                                    Consumer<UserProvider>(
                                      builder: (context, provider, child) {
                                        return _ModernStatCard(
                                          title: 'Pickup',
                                          value: provider.isOnline
                                              ? "Enabled"
                                              : "Off",
                                          subtitle: 'Service availability',
                                          icon: Icons.local_shipping_rounded,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Quick Actions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _QuickActionCard(
                                        icon: Icons.inbox_outlined,
                                        title: 'View Requests',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const OrdersScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _QuickActionCard(
                                        icon: Icons.delivery_dining_rounded,
                                        title: 'Track Orders',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const ActiveOrdersScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _QuickActionCard(
                                        icon: Icons.payments_outlined,
                                        title: 'Payments',
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const PaymentsScreen(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _OnlineStatusSection extends StatelessWidget {
  const _OnlineStatusSection();

  @override
  Widget build(BuildContext context) {
    final isOnline = context.select<UserProvider, bool>(
      (provider) => provider.isOnline,
    );

    return GoOnlineSliderCard(
      isOnline: isOnline,
      onCompleted: () async {
        try {
          await context.read<UserProvider>().toggleOnlineStatus();

          if (!context.mounted) return;

          final updatedStatus = context.read<UserProvider>().isOnline;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                updatedStatus ? 'You are now online.' : 'You are now offline.',
              ),
            ),
          );
        } catch (_) {
          if (!context.mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update online status.')),
          );
        }
      },
    );
  }
}

class GoOnlineSliderCard extends StatefulWidget {
  final bool isOnline;
  final Future<void> Function() onCompleted;

  const GoOnlineSliderCard({
    super.key,
    required this.isOnline,
    required this.onCompleted,
  });

  @override
  State<GoOnlineSliderCard> createState() => _GoOnlineSliderCardState();
}

class _GoOnlineSliderCardState extends State<GoOnlineSliderCard> {
  double _dragDx = 0;
  bool _isSubmitting = false;

  @override
  void didUpdateWidget(covariant GoOnlineSliderCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isOnline != widget.isOnline && mounted) {
      _dragDx = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    const double cardHeight = 68;
    const double knobSize = 56;
    final double maxDrag =
        MediaQuery.of(context).size.width - 32 - 24 - knobSize;

    final bool online = widget.isOnline;
    final String label = online ? 'Go offline' : 'Go online';

    final Color backgroundColor = online
        ? const Color(0xFF111827)
        : const Color(0xFF35C47C);

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        height: cardHeight,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.24),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  _isSubmitting ? 'Please wait...' : label,
                  key: ValueKey('${_isSubmitting}_$label'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 6 + _dragDx,
              child: GestureDetector(
                onHorizontalDragUpdate: _isSubmitting
                    ? null
                    : (details) {
                        setState(() {
                          _dragDx = (_dragDx + details.delta.dx).clamp(
                            0,
                            maxDrag,
                          );
                        });
                      },
                onHorizontalDragEnd: _isSubmitting
                    ? null
                    : (_) async {
                        final bool shouldComplete = _dragDx > maxDrag * 0.72;

                        if (!shouldComplete) {
                          setState(() => _dragDx = 0);
                          return;
                        }

                        setState(() => _isSubmitting = true);

                        try {
                          await widget.onCompleted();
                        } finally {
                          if (mounted) {
                            setState(() {
                              _dragDx = 0;
                              _isSubmitting = false;
                            });
                          }
                        }
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: knobSize,
                  height: knobSize,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: const Icon(
                    Icons.double_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _QuickActionCard({required this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.8,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  const _ModernStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernHeaderCard extends StatelessWidget {
  final String operatorName;
  final String businessName;

  const _ModernHeaderCard({
    required this.operatorName,
    required this.businessName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Operator Dashboard',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hello, $operatorName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  businessName,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Manage laundry requests, monitor orders, and stay on top of business activity from one clean dashboard.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class BookingService {
  BookingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _bookingsCollection = 'bookings';

  Stream<List<BookingModel>> streamOperatorBookings(String laundryId) {
    if (laundryId.trim().isEmpty) {
      return Stream.value(<BookingModel>[]);
    }

    return _firestore
        .collection(_bookingsCollection)
        .where('laundrySnapshot.laundryId', isEqualTo: laundryId)
        .snapshots()
        .map((snapshot) {
          final bookings = snapshot.docs
              .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
              .toList();

          bookings.sort((a, b) {
            final aTime =
                a.requestedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime =
                b.requestedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });

          return bookings;
        });
  }
}
