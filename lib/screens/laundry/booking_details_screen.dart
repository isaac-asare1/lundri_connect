import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lundri_connect/screens/chats_screen.dart';

import '../../core/constants/app_colors.dart';
import '../../models/booking_model.dart';

class BookingDetailsScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final TextEditingController _weightController = TextEditingController();
  final BookingDetailsService _service = BookingDetailsService();

  bool _isSavingWeight = false;
  bool _isCompletingBooking = false;

  static const double _pricePerKg = 10.0;

  late String _currentStatus;
  late double _currentTotalAmount;
  late double _currentWeight;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.booking.status;
    _currentTotalAmount = widget.booking.totalPrice.toDouble();
    _currentWeight = widget.booking.estimatedWeightKg.toDouble();

    if (widget.booking.estimatedWeightKg > 0) {
      _weightController.text = widget.booking.estimatedWeightKg.toString();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  double get _enteredWeight {
    return double.tryParse(_weightController.text.trim()) ?? 0;
  }

  double get _calculatedPrice {
    return _enteredWeight * _pricePerKg;
  }

  List<String> get _selectedAddOns {
    return widget.booking.selectedAddOns
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }

  Future<void> _saveWeight() async {
    final weight = _enteredWeight;

    if (weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid weight greater than 0.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSavingWeight = true);

    try {
      final booking = widget.booking;

      final unitBasePrice = booking.estimatedWeightKg > 0
          ? booking.basePrice / booking.estimatedWeightKg
          : 0;

      final recalculatedBasePrice = (weight * unitBasePrice).round();
      final totalPrice =
          recalculatedBasePrice +
          booking.addOnsPrice +
          booking.pickupFee +
          booking.deliveryFee;

      await _service.updateWeightAndPrice(
        bookingId: booking.id,
        actualWeightKg: weight,
        recalculatedBasePrice: recalculatedBasePrice,
        totalPrice: totalPrice,
      );

      if (!mounted) return;

      setState(() {
        _currentWeight = weight;
        _currentTotalAmount = totalPrice.toDouble();
        _currentStatus = 'processing';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Weight updated. New total is GHS ${totalPrice.toStringAsFixed(2)}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update booking: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingWeight = false);
      }
    }
  }

  Future<void> _completeBooking() async {
    setState(() => _isCompletingBooking = true);

    try {
      await _service.completeBooking(widget.booking.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking marked as completed.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete booking: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCompletingBooking = false);
      }
    }
  }

  void _openCustomerChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          booking: widget.booking,
          currentUserRole: 'laundry',
          otherParticipantRole: 'customer',
          otherParticipantId: widget.booking.customerId,
        ),
      ),
    );
  }

  void _openPickupRiderChat() {
    final riderId = widget.booking.pickupRiderId;
    if (riderId == null || riderId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pickup rider assigned yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          booking: widget.booking,
          currentUserRole: 'laundry',
          otherParticipantRole: 'rider',
          otherParticipantId: riderId,
        ),
      ),
    );
  }

  void _openDeliveryRiderChat() {
    final riderId = widget.booking.deliveryRiderId;
    if (riderId == null || riderId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No delivery rider assigned yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          booking: widget.booking,
          currentUserRole: 'laundry',
          otherParticipantRole: 'rider',
          otherParticipantId: riderId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF5F7FB),
        foregroundColor: AppColors.textPrimary,
        centerTitle: true,
        title: const Text(
          'Booking Details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _HeroBookingCard(
              booking: booking,
              status: _currentStatus,
              totalAmount: _currentTotalAmount,
              onCustomerChat: _openCustomerChat,
              onPickupRiderChat: _openPickupRiderChat,
              onDeliveryRiderChat: _openDeliveryRiderChat,
            ),
            const SizedBox(height: 16),

            _SectionCard(
              displayLeadingIcon: false,
              title: 'Customer Information',
              icon: Icons.person_outline_rounded,
              child: Column(
                children: [
                  _ModernInfoTile(
                    icon: Icons.person_rounded,
                    label: 'Customer',
                    value: booking.customerName,
                  ),
                  const SizedBox(height: 12),
                  _ModernInfoTile(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: booking.customerPhone,
                  ),
                  const SizedBox(height: 12),
                  _ModernInfoTile(
                    icon: Icons.badge_outlined,
                    label: 'Pickup Contact',
                    value: booking.customerName,
                  ),
                  const SizedBox(height: 12),
                  _ModernInfoTile(
                    icon: Icons.call_outlined,
                    label: 'Pickup Phone',
                    value: booking.customerPhone,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _SectionCard(
              displayLeadingIcon: false,
              title: 'Booking Information',
              icon: Icons.inventory_2_outlined,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatMiniCard(
                          title: 'Service',
                          value: booking.serviceType,
                          icon: Icons.local_laundry_service_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatMiniCard(
                          title: 'Weight Range',
                          value: '${booking.estimatedWeightKg} kg',
                          icon: Icons.scale_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatMiniCard(
                          title: 'Requested Date',
                          value: booking.requestedAt != null
                              ? '${booking.requestedAt!.day.toString().padLeft(2, '0')}/${booking.requestedAt!.month.toString().padLeft(2, '0')}/${booking.requestedAt!.year}'
                              : '—',
                          icon: Icons.calendar_month_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatMiniCard(
                          title: 'Requested Time',
                          value: booking.requestedAt != null
                              ? '${booking.requestedAt!.hour.toString().padLeft(2, '0')}:${booking.requestedAt!.minute.toString().padLeft(2, '0')}'
                              : '—',
                          icon: Icons.access_time_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatMiniCard(
                          title: 'Current Amount',
                          value:
                              'GHS ${_currentTotalAmount.toStringAsFixed(2)}',
                          icon: Icons.payments_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatMiniCard(
                          title: 'Payment Status',
                          value: booking.paymentStatus,
                          icon: Icons.receipt_long_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatMiniCard(
                          title: 'Actual Weight',
                          value: _currentWeight > 0
                              ? '${_currentWeight.toStringAsFixed(1)} kg'
                              : '—',
                          icon: Icons.monitor_weight_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatMiniCard(
                          title: 'Booking Status',
                          value: _currentStatus,
                          icon: Icons.sync_alt_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_selectedAddOns.isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Selected Add-Ons',
                icon: Icons.auto_awesome_outlined,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _selectedAddOns
                      .map((addOn) => _AddOnChip(label: addOn))
                      .toList(),
                ),
              ),
            ],

            const SizedBox(height: 16),

            _SectionCard(
              title: 'Addresses',
              icon: Icons.location_on_outlined,
              child: Column(
                children: [
                  _AddressTile(
                    title: 'Pickup Address',
                    address: booking.pickupAddress,
                    icon: Icons.upload_outlined,
                  ),
                  const SizedBox(height: 12),
                  _AddressTile(
                    title: 'Dropoff Address',
                    address: booking.customerAddress,
                    icon: Icons.download_outlined,
                  ),
                ],
              ),
            ),

            if (booking.customerNotes.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Customer Note',
                icon: Icons.sticky_note_2_outlined,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.08),
                    ),
                  ),
                  child: Text(
                    booking.customerNotes,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            _SectionCard(
              title: 'Update Weight & Price',
              icon: Icons.scale_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: Color(0xFFB45309),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Pricing is calculated using a fixed rate of GHS 10 per kg.',
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Enter actual weight (kg)',
                      hintText: 'e.g. 4.5',
                      prefixIcon: const Icon(Icons.scale_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFD),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: AppColors.primary.withOpacity(0.28),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.10),
                          AppColors.primary.withOpacity(0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Calculated Total',
                          style: TextStyle(
                            fontSize: 12.8,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'GHS ${_calculatedPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSavingWeight ? null : _saveWeight,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSavingWeight
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Save Weight & Update Price',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCompletingBooking ? null : _completeBooking,
                icon: _isCompletingBooking
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: const Text(
                  'Complete Booking',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
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

class BookingDetailsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateWeightAndPrice({
    required String bookingId,
    required double actualWeightKg,
    required int recalculatedBasePrice,
    required int totalPrice,
  }) async {
    final bookingRef = _firestore.collection('bookings').doc(bookingId);

    await bookingRef.update({
      'items.0.actualWeightKg': actualWeightKg,
      'pricing.basePrice': recalculatedBasePrice,
      'pricing.totalPrice': totalPrice,
      'status': 'processing',
      'timeline.washingStartedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await bookingRef.collection('status_history').add({
      'status': 'processing',
      'title': 'Laundry Processing Started',
      'description':
          'The laundry weighed the clothes and started processing the order.',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeBooking(String bookingId) async {
    final bookingRef = _firestore.collection('bookings').doc(bookingId);

    await bookingRef.update({
      'status': 'completed',
      'timeline.deliveredAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await bookingRef.collection('status_history').add({
      'status': 'completed',
      'title': 'Booking Completed',
      'description': 'The booking has been marked as completed.',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

class _HeroBookingCard extends StatelessWidget {
  final BookingModel booking;
  final String status;
  final double totalAmount;
  final VoidCallback onCustomerChat;
  final VoidCallback onPickupRiderChat;
  final VoidCallback onDeliveryRiderChat;

  const _HeroBookingCard({
    required this.booking,
    required this.status,
    required this.totalAmount,
    required this.onCustomerChat,
    required this.onPickupRiderChat,
    required this.onDeliveryRiderChat,
  });

  String _cleanText(String value, {String fallback = '—'}) {
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  @override
  Widget build(BuildContext context) {
    final hasPickupRider =
        booking.pickupRiderId != null &&
        booking.pickupRiderId!.trim().isNotEmpty;
    final hasDeliveryRider =
        booking.deliveryRiderId != null &&
        booking.deliveryRiderId!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
                  _cleanText(
                    booking.customerName,
                    fallback: 'Customer Booking',
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),
              _HeaderStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _cleanText(
              booking.serviceType.replaceAll('_', ' '),
              fallback: 'Laundry service',
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withOpacity(0.04)),
            ),
            child: Row(
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.payments_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Amount to pay',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  'GHS ${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ChatQuickButton(
                  label: 'Customer',
                  icon: Icons.person_outline_rounded,
                  onTap: onCustomerChat,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ChatQuickButton(
                  label: 'Pickup Rider',
                  icon: Icons.delivery_dining_outlined,
                  onTap: hasPickupRider ? onPickupRiderChat : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ChatQuickButton(
                  label: 'Delivery Rider',
                  icon: Icons.local_shipping_outlined,
                  onTap: hasDeliveryRider ? onDeliveryRiderChat : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatQuickButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _ChatQuickButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDisabled
              ? const Color(0xFFF3F4F6)
              : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDisabled
                ? const Color(0xFFE5E7EB)
                : AppColors.primary.withOpacity(0.14),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isDisabled ? AppColors.textSecondary : AppColors.primary,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.8,
                fontWeight: FontWeight.w700,
                color: isDisabled ? AppColors.textSecondary : AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool displayLeadingIcon;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.displayLeadingIcon = true,
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
            color: Colors.black.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              displayLeadingIcon
                  ? Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 22),
                    )
                  : const SizedBox.shrink(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ModernInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ModernInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  String get _displayValue {
    final text = value.trim();
    return text.isEmpty ? '—' : text;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
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
                const SizedBox(height: 4),
                Text(
                  _displayValue,
                  style: const TextStyle(
                    fontSize: 14.4,
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

class _StatMiniCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatMiniCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  String get _displayValue {
    final text = value.trim();
    return text.isEmpty ? '—' : text;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.4,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _displayValue,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final String title;
  final String address;
  final IconData icon;

  const _AddressTile({
    required this.title,
    required this.address,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cleanedAddress = address.trim().isEmpty ? '—' : address.trim();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  cleanedAddress,
                  style: const TextStyle(
                    fontSize: 14.2,
                    height: 1.5,
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

class _AddOnChip extends StatelessWidget {
  final String label;

  const _AddOnChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.2,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStatusChip extends StatelessWidget {
  final String status;

  const _HeaderStatusChip({required this.status});

  Color _backgroundColor(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
      case 'requested':
        return const Color(0xFFFFF3E8);
      case 'looking_for_a_rider':
        return const Color(0xFFEAF2FF);
      case 'arrived_at_laundry':
        return const Color(0xFFF3F0FF);
      case 'completed':
        return const Color(0xFFEAF8EE);
      case 'cancelled':
      case 'laundry_rejected':
        return const Color(0xFFFDECEC);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _textColor(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
      case 'requested':
        return const Color(0xFFB45309);
      case 'looking_for_a_rider':
        return const Color(0xFF1D4ED8);
      case 'arrived_at_laundry':
        return const Color(0xFF7C3AED);
      case 'completed':
        return const Color(0xFF15803D);
      case 'cancelled':
      case 'laundry_rejected':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF374151);
    }
  }

  String _formatStatus(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((e) => e.trim().isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: _backgroundColor(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _formatStatus(status),
        style: TextStyle(
          fontSize: 12.4,
          fontWeight: FontWeight.w800,
          color: _textColor(status),
        ),
      ),
    );
  }
}
