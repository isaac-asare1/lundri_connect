import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/loading_widget.dart';
import 'booking_details_screen.dart';
import 'chats_screen.dart';

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
    final operatorId = userProvider.currentUser?.id ?? '';

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
            child: TabBar(
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
                Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text('New Orders'),
                  ),
                ),
                Tab(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text('Active Orders'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: userProvider.isLoading
          ? const LoadingWidget(message: 'Loading orders...')
          : operatorId.isEmpty
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
                  stream: _ordersService.streamNewOrders(operatorId),
                  emptyTitle: 'No new orders',
                  emptySubtitle:
                      'Incoming laundry booking requests will appear here.',
                  onRefresh: _refresh,
                  itemBuilder: (booking) => _NewOrderCard(
                    booking: booking,
                    onAccept: () async {
                      await _ordersService.acceptOrder(booking.id);

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Order accepted. Looking for a rider now.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    onReject: () async {
                      await _ordersService.rejectOrder(booking.id);

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Order rejected'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
                _OrdersListView(
                  stream: _ordersService.streamActiveOrders(operatorId),
                  emptyTitle: 'No active orders',
                  emptySubtitle:
                      'Accepted and in-progress orders will appear here.',
                  onRefresh: _refresh,
                  itemBuilder: (booking) => _ActiveOrderCard(
                    booking: booking,
                    onTap:
                        booking.status.trim().toLowerCase() !=
                            'arrived_at_laundry'
                        ? () {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'The laundry has not yet arrived.',
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

                    onChatTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LaundryChatScreen(
                            booking: booking,
                            currentUserRole: 'laundry',
                          ),
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
  final Future<void> Function() onReject;

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

  @override
  Widget build(BuildContext context) {
    final hasCustomerNote = widget.booking.customerNote.trim().isNotEmpty;

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
                        widget.booking.customerNote,
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
                          : () async {
                              setState(() => _isRejecting = true);
                              try {
                                await widget.onReject();
                              } finally {
                                if (mounted) {
                                  setState(() => _isRejecting = false);
                                }
                              }
                            },
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
  final VoidCallback onChatTap;

  const _ActiveOrderCard({
    required this.booking,
    required this.onTap,
    required this.onChatTap,
  });

  bool get _showChatButton =>
      booking.status.trim().toLowerCase() == 'arrived_at_laundry';

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
                value: booking.dropoffAddress,
              ),
              const SizedBox(height: 10),
              _InfoRow(
                icon: Icons.payments_outlined,
                label: 'Amount',
                value: 'GHS ${booking.totalAmount.toStringAsFixed(2)}',
              ),
              if (_showChatButton) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onChatTap,
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text(
                      'Open Chat',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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

    if (normalized == 'requested' ||
        normalized == 'pending' ||
        normalized == 'awaiting_laundry_acceptance') {
      return const Color(0xFFF59E0B);
    }

    if (normalized == 'looking_for_a_rider' ||
        normalized == 'pickup_rider_assigned' ||
        normalized == 'pickup_started' ||
        normalized == 'picked_up' ||
        normalized == 'arrived_at_laundry' ||
        normalized == 'processing' ||
        normalized == 'ready_for_dropoff' ||
        normalized == 'delivery_rider_assigned' ||
        normalized == 'delivery_started' ||
        normalized == 'delivery_in_progress') {
      return const Color(0xFF10B981);
    }

    if (normalized == 'rejected' ||
        normalized == 'laundry_rejected' ||
        normalized == 'cancelled') {
      return const Color(0xFFEF4444);
    }

    if (normalized == 'delivered') {
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

class OperatorOrdersService {
  OperatorOrdersService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<BookingModel>> streamNewOrders(String laundryId) {
    return _firestore
        .collection('bookings')
        .where('laundryId', isEqualTo: laundryId)
        .where(
          'status',
          whereIn: const [
            'pending',
            'requested',
            'awaiting_laundry_acceptance',
          ],
        )
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
        .where('laundryId', isEqualTo: laundryId)
        .where(
          'status',
          whereIn: const [
            'looking_for_a_rider',
            'pickup_rider_assigned',
            'pickup_started',
            'picked_up',
            'arrived_at_laundry',
            'processing',
            'ready_for_dropoff',
            'delivery_rider_assigned',
            'delivery_started',
            'delivery_in_progress',
          ],
        )
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

  Future<void> acceptOrder(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'looking_for_a_rider',
      'timeline.laundryAcceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'cancellation': null,
      'notes.laundry': '',
    });
  }

  Future<void> rejectOrder(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'laundry_rejected',
      'updatedAt': FieldValue.serverTimestamp(),
      'cancellation': {
        'cancelledBy': 'laundry',
        'reason': 'Rejected by laundry operator.',
      },
      'timeline.cancelledAt': FieldValue.serverTimestamp(),
    });
  }
}
