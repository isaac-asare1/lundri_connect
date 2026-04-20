import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
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
      await _service.updateWeightAndPrice(
        bookingId: widget.booking.id,
        weightKg: weight,
        totalAmount: _calculatedPrice,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Weight saved. Total updated to GHS ${_calculatedPrice.toStringAsFixed(2)}.',
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
              calculatedPrice: _calculatedPrice,
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
                    value: booking.pickupContactName,
                  ),
                  const SizedBox(height: 12),
                  _ModernInfoTile(
                    icon: Icons.call_outlined,
                    label: 'Pickup Phone',
                    value: booking.pickupContactPhone,
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
                          value: booking.weightRange,
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
                          title: 'Pickup Date',
                          value: booking.pickupDate,
                          icon: Icons.calendar_month_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatMiniCard(
                          title: 'Pickup Time',
                          value: booking.pickupTimeSlot,
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
                              'GHS ${booking.totalAmount.toStringAsFixed(2)}',
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
                ],
              ),
            ),
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
                    address: booking.dropoffAddress,
                    icon: Icons.download_outlined,
                  ),
                ],
              ),
            ),

            if (booking.customerNote.trim().isNotEmpty) ...[
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
                    booking.customerNote,
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
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isSavingWeight
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                              ),
                            )
                          : const Text(
                              'Save Weight & Update Price',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
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
                onPressed: () {},
                // onPressed: _isCompletingBooking ? null : _completeBooking,
                icon: _isCompletingBooking
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
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
    required double weightKg,
    required double totalAmount,
  }) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'estimatedWeightKg': weightKg,
      'totalAmount': totalAmount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeBooking(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class _HeroBookingCard extends StatelessWidget {
  final BookingModel booking;
  final double calculatedPrice;

  const _HeroBookingCard({
    required this.booking,
    required this.calculatedPrice,
  });

  String _cleanText(String value, {String fallback = '—'}) {
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  @override
  Widget build(BuildContext context) {
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
              _HeaderStatusChip(status: booking.status),
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
          const SizedBox(height: 16),

          Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withOpacity(0.04)),
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
                  child: Icon(
                    Icons.payments_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Amount to pay',
                  style: const TextStyle(
                    fontSize: 12.4,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'GHS ${booking.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    height: 1.3,
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
                  : SizedBox.shrink(),
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
