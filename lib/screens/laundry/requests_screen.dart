import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/app_user_model.dart';
import '../../models/booking_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/loading_widget.dart';
import 'booking_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final OperatorOrdersService _ordersService = OperatorOrdersService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    Future.microtask(() async {
      await context.read<UserProvider>().loadCurrentUser();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<UserProvider>().loadCurrentUser();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final laundryId = userProvider.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        title: const Text(
          'Orders',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(74),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F7),
              borderRadius: BorderRadius.circular(18),
            ),
            child: laundryId.isEmpty
                ? TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(child: Text('New Orders')),
                      Tab(child: Text('Active Orders')),
                    ],
                  )
                : StreamBuilder<Map<String, int>>(
                    stream: _ordersService.streamOrderCounts(laundryId),
                    builder: (context, snapshot) {
                      final counts =
                          snapshot.data ?? const {'new': 0, 'active': 0};

                      return TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        dividerColor: Colors.transparent,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.textSecondary,
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: [
                          Tab(
                            child: _TabLabelWithBadge(
                              label: 'New Orders',
                              count: counts['new'] ?? 0,
                              isSelected: _tabController.index == 0,
                            ),
                          ),
                          Tab(
                            child: _TabLabelWithBadge(
                              label: 'Active Orders',
                              count: counts['active'] ?? 0,
                              isSelected: _tabController.index == 1,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
      body: userProvider.isLoading
          ? const LoadingWidget(message: 'Loading orders...')
          : laundryId.isEmpty
          ? const Center(
              child: Text(
                'Operator account not found.',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _OrdersListView(
                  stream: _ordersService.streamNewOrders(laundryId),
                  emptyTitle: 'No new orders',
                  emptySubtitle:
                      'Incoming laundry booking requests will appear here.',
                  onRefresh: _refresh,
                  itemBuilder: (booking) => _NewOrderCard(
                    booking: booking,
                    onAccept: () async {
                      await _ordersService.acceptOrder(
                        bookingId: booking.id,
                        currentUser: userProvider.currentUser,
                      );

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Order accepted. Looking for a pickup rider now.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    onReject: (reason, note) async {
                      await _ordersService.rejectOrder(
                        bookingId: booking.id,
                        laundryId: laundryId,
                        reason: reason,
                        note: note,
                      );

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Order rejected. Reassigning to another laundry.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
                _OrdersListView(
                  stream: _ordersService.streamActiveOrders(laundryId),
                  emptyTitle: 'No active orders',
                  emptySubtitle:
                      'Accepted and in-progress orders will appear here.',
                  onRefresh: _refresh,
                  itemBuilder: (booking) => _ActiveOrderCard(
                    booking: booking,
                    onTap:
                        booking.status.trim().toLowerCase() ==
                                'looking_for_pickup_rider' ||
                            booking.status.trim().toLowerCase() ==
                                'pickup_rider_assigned'
                        ? () {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'A pickup rider has not completed pickup yet.',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BookingDetailsScreen(booking: booking),
                              ),
                            );
                          },
                  ),
                ),
              ],
            ),
    );
  }
}

class _TabLabelWithBadge extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;

  const _TabLabelWithBadge({
    required this.label,
    required this.count,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final badgeBg = isSelected
        ? Colors.white.withOpacity(0.18)
        : AppColors.primary.withOpacity(0.10);

    final badgeTextColor = isSelected ? Colors.white : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(minWidth: 22),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersListView extends StatelessWidget {
  final Stream<List<BookingModel>> stream;
  final String emptyTitle;
  final String emptySubtitle;
  final Future<void> Function() onRefresh;
  final Widget Function(BookingModel booking) itemBuilder;

  const _OrdersListView({
    required this.stream,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onRefresh,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BookingModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: 'Loading orders...');
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Failed to load orders.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.62,
                  child: _EmptyOrdersView(
                    title: emptyTitle,
                    subtitle: emptySubtitle,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) => itemBuilder(bookings[index]),
          ),
        );
      },
    );
  }
}

class _NewOrderCard extends StatefulWidget {
  final BookingModel booking;
  final Future<void> Function() onAccept;
  final Future<void> Function(String reason, String note) onReject;

  const _NewOrderCard({
    required this.booking,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_NewOrderCard> createState() => _NewOrderCardState();
}

class _NewOrderCardState extends State<_NewOrderCard> {
  bool _expanded = false;
  bool _isAccepting = false;
  bool _isRejecting = false;

  Future<void> _handleReject() async {
    final result = await showModalBottomSheet<_CancelOrderResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CancelOrderSheet(),
    );

    if (result == null) return;

    setState(() => _isRejecting = true);
    try {
      await widget.onReject(result.reason, result.note);
    } finally {
      if (mounted) {
        setState(() => _isRejecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomerNote = widget.booking.customerNotes.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: hasCustomerNote
            ? () {
                setState(() {
                  _expanded = !_expanded;
                });
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
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
              _OrderTopRow(
                customerName: widget.booking.customerName,
                status: widget.booking.status,
                trailing: hasCustomerNote
                    ? Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 32,
                      )
                    : null,
              ),
              const SizedBox(height: 14),
              _InfoRow(
                icon: Icons.local_laundry_service_outlined,
                label: 'Service',
                value: widget.booking.serviceType,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone number',
                value: widget.booking.customerPhone,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Pickup',
                value: widget.booking.pickupAddress,
              ),
              if (hasCustomerNote && _expanded) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.12),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.sticky_note_2_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Customer Note',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.booking.customerNotes,
                        style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isAccepting || _isRejecting
                          ? null
                          : _handleReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isRejecting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Reject',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isAccepting || _isRejecting
                          ? null
                          : () async {
                              setState(() => _isAccepting = true);
                              try {
                                await widget.onAccept();
                              } finally {
                                if (mounted) {
                                  setState(() => _isAccepting = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isAccepting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Accept',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
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
}

class _ActiveOrderCard extends StatelessWidget {
  final BookingModel booking;
  final VoidCallback onTap;

  const _ActiveOrderCard({required this.booking, required this.onTap});

  bool get _showRequestDeliverySlider {
    final normalized = booking.status.trim().toLowerCase();
    return normalized == 'processing' || normalized == 'arrived_at_laundry';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
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
              _OrderTopRow(
                customerName: booking.customerName,
                status: booking.status,
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              _InfoRow(
                icon: Icons.local_laundry_service_outlined,
                label: 'Service',
                value: booking.serviceType,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Customer',
                value: booking.customerPhone,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Dropoff',
                value: booking.customerAddress,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.payments_outlined,
                label: 'Amount',
                value: 'GHS ${booking.totalPrice}',
              ),
              if (_showRequestDeliverySlider) ...[
                const SizedBox(height: 16),
                _RequestDeliveryRiderSlider(bookingId: booking.id),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestDeliveryRiderSlider extends StatefulWidget {
  final String bookingId;

  const _RequestDeliveryRiderSlider({required this.bookingId});

  @override
  State<_RequestDeliveryRiderSlider> createState() =>
      _RequestDeliveryRiderSliderState();
}

class _RequestDeliveryRiderSliderState
    extends State<_RequestDeliveryRiderSlider> {
  double _dragDx = 0;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double cardHeight = 64;
        const double knobSize = 46;
        const double horizontalPadding = 8;

        final double maxTravel =
            constraints.maxWidth - knobSize - (horizontalPadding * 2);

        final double knobLeft = _dragDx.clamp(0.0, maxTravel);

        return Container(
          height: cardHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF3FC37A),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            children: [
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _isSubmitting ? 0.55 : 1,
                  child: const Text(
                    'Request for delivery rider',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: horizontalPadding + knobLeft,
                top: 9,
                child: GestureDetector(
                  onHorizontalDragUpdate: _isSubmitting
                      ? null
                      : (details) {
                          setState(() {
                            _dragDx += details.delta.dx;
                          });
                        },
                  onHorizontalDragEnd: _isSubmitting
                      ? null
                      : (_) async {
                          final bool shouldTrigger =
                              knobLeft > maxTravel * 0.60;

                          setState(() {
                            _dragDx = 0;
                          });

                          if (!shouldTrigger) return;

                          setState(() {
                            _isSubmitting = true;
                          });

                          try {
                            await FirebaseFirestore.instance
                                .collection('bookings')
                                .doc(widget.bookingId)
                                .update({
                                  'status': 'ready_for_dropoff',
                                  'updatedAt': FieldValue.serverTimestamp(),
                                  'timeline.readyForDropoffAt':
                                      FieldValue.serverTimestamp(),
                                });

                            if (!mounted) return;

                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Delivery rider request started.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                          } catch (e) {
                            if (!mounted) return;

                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to request delivery rider: $e',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isSubmitting = false;
                              });
                            }
                          }
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _isSubmitting
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.keyboard_double_arrow_right_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrderTopRow extends StatelessWidget {
  final String customerName;
  final String status;
  final Widget? trailing;

  const _OrderTopRow({
    required this.customerName,
    required this.status,
    this.trailing,
  });

  Color _statusColor(String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized == 'offered_to_laundry') {
      return const Color(0xFFF59E0B);
    }

    if (normalized == 'pending' ||
        normalized == 'looking_for_pickup_rider' ||
        normalized == 'pickup_rider_assigned' ||
        normalized == 'pickup_started' ||
        normalized == 'arrived_at_laundry' ||
        normalized == 'processing' ||
        normalized == 'arrived_at_pickup' ||
        normalized == 'ready_for_dropoff' ||
        normalized == 'delivery_in_progress') {
      return const Color(0xFF10B981);
    }

    if (normalized == 'rejected_by_laundry' ||
        normalized == 'cancelled' ||
        normalized == 'no_laundry_found') {
      return const Color(0xFFEF4444);
    }

    if (normalized == 'completed') {
      return const Color(0xFF3B82F6);
    }

    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return Row(
      children: [
        Expanded(
          child: Text(
            customerName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            status.replaceAll('_', ' '),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 38,
          width: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
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
                value.isEmpty ? '—' : value,
                style: const TextStyle(
                  fontSize: 14.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyOrdersView extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyOrdersView({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 58,
              color: AppColors.iconMuted,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
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

class _CancelOrderResult {
  final String reason;
  final String note;

  const _CancelOrderResult({required this.reason, required this.note});
}

class _CancelOrderSheet extends StatefulWidget {
  const _CancelOrderSheet();

  @override
  State<_CancelOrderSheet> createState() => _CancelOrderSheetState();
}

class _CancelOrderSheetState extends State<_CancelOrderSheet> {
  final TextEditingController _noteController = TextEditingController();

  final List<String> _reasons = const [
    'Laundry is closing soon',
    'Laundry is fully booked',
    'Pickup cannot be arranged',
    'Service unavailable',
    'Area is out of coverage',
    'Other',
  ];

  String _selectedReason = 'Laundry is fully booked';

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop(
      _CancelOrderResult(
        reason: _selectedReason,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Reject order',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select a reason and add a short note.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _reasons.map((reason) {
                  final isSelected = reason == _selectedReason;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedReason = reason);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.12)
                            : const Color(0xFFF6F7FB),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.black.withOpacity(0.06),
                        ),
                      ),
                      child: Text(
                        reason,
                        style: TextStyle(
                          fontSize: 12.8,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _noteController,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Add an optional note...',
                  filled: true,
                  fillColor: const Color(0xFFF7F8FC),
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: Colors.black.withOpacity(0.05),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.black.withOpacity(0.08)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Confirm reject',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
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
}

class OperatorOrdersService {
  OperatorOrdersService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const List<String> _newStatuses = [
    'offered_to_laundry',
    'awaiting_laundry_acceptance',
    'pending',
  ];

  static const List<String> _activeStatuses = [
    'looking_for_pickup_rider',
    'pickup_rider_assigned',
    'pickup_started',
    'arrived_at_pickup',
    'arrived_at_laundry',
    'processing',
    'ready_for_dropoff',
    'delivery_in_progress',
    'completed',
  ];

  Stream<List<BookingModel>> streamNewOrders(String laundryId) {
    return _firestore
        .collection('bookings')
        .where('laundrySnapshot.id', isEqualTo: laundryId)
        .where('status', whereIn: _newStatuses)
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

  Stream<List<BookingModel>> streamActiveOrders(String laundryId) {
    return _firestore
        .collection('bookings')
        .where('laundrySnapshot.id', isEqualTo: laundryId)
        .where('status', whereIn: _activeStatuses)
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

  Stream<Map<String, int>> streamOrderCounts(String laundryId) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('laundrySnapshot.id', isEqualTo: laundryId)
        .snapshots()
        .map((snapshot) {
          int newCount = 0;
          int activeCount = 0;

          for (final doc in snapshot.docs) {
            final status = (doc.data()['status'] ?? '').toString();

            if (_newStatuses.contains(status)) {
              newCount++;
            } else if (_activeStatuses.contains(status)) {
              activeCount++;
            }
          }

          return {'new': newCount, 'active': activeCount};
        });
  }

  Future<void> acceptOrder({
    required String bookingId,
    required AppUserModel? currentUser,
  }) async {
    if (currentUser == null) {
      throw Exception('Current user is null.');
    }

    final laundryDoc = await _firestore
        .collection('laundries')
        .doc(currentUser.id)
        .get();

    final laundryData = laundryDoc.data() ?? <String, dynamic>{};
    final profile = _asMap(laundryData['profile']);
    final contact = _asMap(laundryData['contact']);
    final location = _asMap(laundryData['location']);

    final laundryName = _readString(profile['name']) ?? currentUser.fullName;
    final laundryPhone =
        _readString(contact['phoneNumber']) ?? currentUser.phoneNumber;
    final laundryPhotoUrl = _readString(profile['photoUrl']) ?? '';
    final laundryAddressLine = _readString(location['addressLine']) ?? '';
    final latitude = _readString(location['latitude']);
    final longitude = _readString(location['longitude']);

    final bookingRef = _firestore.collection('bookings').doc(bookingId);

    await bookingRef.update({
      'status': 'looking_for_pickup_rider',
      'updatedAt': FieldValue.serverTimestamp(),
      'timeline.acceptedAt': FieldValue.serverTimestamp(),
      'laundryAssignment.assignedAutomatically': true,
      'laundryAssignment.assignedAt': FieldValue.serverTimestamp(),
      'laundrySnapshot.id': currentUser.id,
      'laundrySnapshot.laundryName': laundryName,
      'laundrySnapshot.laundryPhone': laundryPhone,
      'laundrySnapshot.laundryPhotoUrl': laundryPhotoUrl,
      'laundrySnapshot.addressLine': laundryAddressLine,
      'laundrySnapshot.latitude': latitude,
      'laundrySnapshot.longitude': longitude,
    });

    await bookingRef.collection('status_history').add({
      'status': 'looking_for_pickup_rider',
      'title': 'Laundry Accepted',
      'description':
          'The laundry accepted this booking and the system is now looking for a pickup rider.',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectOrder({
    required String bookingId,
    required String laundryId,
    required String reason,
    required String note,
  }) async {
    final bookingRef = _firestore.collection('bookings').doc(bookingId);

    await bookingRef.update({
      'status': 'awaiting_laundry_assignment',
      'updatedAt': FieldValue.serverTimestamp(),
      'rejectedLaundryIds': FieldValue.arrayUnion([laundryId]),
      'laundryId': null,
      'laundryName': null,
      'laundryPhone': null,
      'laundryPhotoUrl': null,
      'laundryOffer.offeredLaundryId': null,
      'laundryOffer.offeredAt': null,
      'laundryOffer.offerExpiresAt': null,
    });

    await bookingRef.collection('status_history').add({
      'status': 'awaiting_laundry_assignment',
      'title': 'Laundry Rejected',
      'description': note.trim().isEmpty
          ? 'Laundry rejected this booking because: $reason.'
          : 'Laundry rejected this booking because: $reason. Note: $note',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  String? _readString(dynamic value) {
    if (value == null) return null;
    final result = value.toString().trim();
    return result.isEmpty ? null : result;
  }
}
