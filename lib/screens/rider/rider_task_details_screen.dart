import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:lundri_connect/core/constants/app_colors.dart';
import 'package:lundri_connect/widgets/loading_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/routes/route_names.dart';
import '../../models/booking_model.dart';
import '../others/chats_screen.dart';

class RiderTaskDetailsScreen extends StatelessWidget {
  final String bookingId;

  const RiderTaskDetailsScreen({super.key, required this.bookingId});

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

    final bookingStream = FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F6),
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: bookingStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading task...');
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load task.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Task not found.', style: TextStyle(fontSize: 15)),
            );
          }

          final raw = snapshot.data!.data() ?? <String, dynamic>{};
          final booking = BookingModel.fromMap(raw, snapshot.data!.id);
          final timelineMap = _asMap(raw['timeline']);

          final DateTime? deliveryPickupArrivedAt = _parseTimestamp(
            timelineMap['deliveryPickupArrivedAt'],
          );

          final bool isDeliveryTask =
              booking.deliveryRiderId == currentUser.uid &&
              (booking.status == 'delivery_in_progress' ||
                  booking.status == 'arrived_at_customer' ||
                  booking.status == 'completed');

          final bool isPickupTask =
              booking.pickupRiderId == currentUser.uid && !isDeliveryTask;

          if (!isPickupTask && !isDeliveryTask) {
            return const Center(
              child: Text(
                'This task is not assigned to you.',
                style: TextStyle(fontSize: 15),
              ),
            );
          }

          final _TaskStageInfo stage = _buildStageInfo(
            booking: booking,
            isPickupTask: isPickupTask,
            isDeliveryTask: isDeliveryTask,
            deliveryPickupArrivedAt: deliveryPickupArrivedAt,
          );

          final bool showLaundryContactCard =
              (isPickupTask &&
                  (booking.status == 'arrived_at_pickup' ||
                      booking.status == 'arrived_at_laundry')) ||
              isDeliveryTask;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ParticipantContactCard(
                  name: booking.customerName,
                  phone: booking.customerPhone,
                  photoUrl: booking.customerPhotoUrl,
                  fallbackIcon: Icons.person_rounded,
                  description: 'Contact the customer',
                  onCall: () => _makePhoneCall(booking.customerPhone),
                  onChat: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          booking: booking,
                          currentUserRole: 'rider',
                          otherParticipantRole: 'customer',
                          otherParticipantId: booking.customerId,
                        ),
                      ),
                    );
                  },
                ),
                if (showLaundryContactCard) ...[
                  const SizedBox(height: 14),
                  _ParticipantContactCard(
                    name:
                        (booking.laundrySnapshotName?.trim().isNotEmpty == true)
                        ? booking.laundrySnapshotName!
                        : 'Laundry',
                    phone:
                        (booking.laundrySnapshotPhone?.trim().isNotEmpty ==
                            true)
                        ? booking.laundrySnapshotPhone!
                        : '',
                    photoUrl:
                        (booking.laundrySnapshotPhotoUrl?.trim().isNotEmpty ==
                            true)
                        ? booking.laundrySnapshotPhotoUrl!
                        : '',
                    fallbackIcon: Icons.local_laundry_service_rounded,
                    description: "Contact the laundry",
                    onCall: () => _makePhoneCall(
                      (booking.laundrySnapshotPhone?.trim().isNotEmpty == true)
                          ? booking.laundrySnapshotPhone!
                          : '',
                    ),
                    onChat: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            booking: booking,
                            currentUserRole: 'rider',
                            otherParticipantRole: 'laundry',
                            otherParticipantId: booking.laundrySnapshotId,
                          ),
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 14),
                _DestinationSummaryCard(
                  isPickupTask: isPickupTask,
                  isDeliveryTask: isDeliveryTask,
                  booking: booking,
                  deliveryPickupArrivedAt: deliveryPickupArrivedAt,
                ),
                const SizedBox(height: 14),
                _StageCard(
                  title: stage.title,
                  description: stage.description,
                  primaryButtonText: stage.navigateLabel,
                  secondaryButtonText: stage.confirmLabel,
                  onNavigate: () => _openDirectionsForStage(
                    booking: booking,
                    stage: stage.stage,
                    isPickupTask: isPickupTask,
                    isDeliveryTask: isDeliveryTask,
                  ),
                  onConfirm: () async {
                    await _confirmStageArrival(
                      booking: booking,
                      stage: stage.stage,
                      isPickupTask: isPickupTask,
                      isDeliveryTask: isDeliveryTask,
                      deliveryPickupArrivedAt: deliveryPickupArrivedAt,
                    );

                    if (!context.mounted) return;

                    final bool shouldShowCompleteCard =
                        stage.stage == RiderTaskStage.goToDropoff ||
                        stage.stage == RiderTaskStage.deliveryTaskDone;

                    if (shouldShowCompleteCard) {
                      await _showCompleteOrderDialog(context);
                    }
                  },
                  isActionComplete: stage.isCompleted,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Future<void> _showCompleteOrderDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 26),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: Lottie.asset(
                    'assets/animations/completeOrder.json',
                    repeat: false,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Task completed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Great work. This order step has been updated successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        RouteNames.mainNavigation,
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF3FC37A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static _TaskStageInfo _buildStageInfo({
    required BookingModel booking,
    required bool isPickupTask,
    required bool isDeliveryTask,
    required DateTime? deliveryPickupArrivedAt,
  }) {
    if (isPickupTask) {
      switch (booking.status) {
        case 'pickup_started':
          return const _TaskStageInfo(
            stage: RiderTaskStage.goToPickup,
            title: 'Go to Pickup Point',
            description:
                'Navigate to the customer pickup point, then confirm once you arrive.',
            navigateLabel: 'Go to pickup point',
            confirmLabel: 'I have arrived at pickup point',
            isCompleted: false,
          );
        case 'arrived_at_pickup':
          return const _TaskStageInfo(
            stage: RiderTaskStage.goToDropoff,
            title: 'Go to Drop-off Point',
            description:
                'You have reached the pickup point. Now head to the laundry drop-off point.',
            navigateLabel: 'Go to drop-off point',
            confirmLabel: 'I have arrived at drop-off point',
            isCompleted: false,
          );
        case 'arrived_at_laundry':
          return const _TaskStageInfo(
            stage: RiderTaskStage.pickupTaskDone,
            title: 'Pickup Task Completed',
            description:
                'You have arrived at the laundry drop-off point. This pickup leg is done.',
            navigateLabel: 'Pickup completed',
            confirmLabel: 'Pickup completed',
            isCompleted: true,
          );
        default:
          return const _TaskStageInfo(
            stage: RiderTaskStage.goToPickup,
            title: 'Go to Pickup Point',
            description:
                'Navigate to the customer pickup point, then confirm once you arrive.',
            navigateLabel: 'Go to pickup point',
            confirmLabel: 'I have arrived at pickup point',
            isCompleted: false,
          );
      }
    }

    if (isDeliveryTask) {
      if (booking.status == 'delivery_in_progress') {
        if (deliveryPickupArrivedAt == null) {
          return const _TaskStageInfo(
            stage: RiderTaskStage.goToPickup,
            title: 'Go to Pickup Point',
            description:
                'Navigate to the laundry pickup point to collect the washed clothes, then confirm once you arrive.',
            navigateLabel: 'Go to pickup point',
            confirmLabel: 'I have arrived at pickup point',
            isCompleted: false,
          );
        }

        return const _TaskStageInfo(
          stage: RiderTaskStage.goToDropoff,
          title: 'Go to Drop-off Point',
          description:
              'You have reached the laundry and picked up the washed clothes. Now head to the customer.',
          navigateLabel: 'Go to drop-off point',
          confirmLabel: 'I have arrived at drop-off point',
          isCompleted: false,
        );
      }

      if (booking.status == 'arrived_at_customer') {
        return const _TaskStageInfo(
          stage: RiderTaskStage.deliveryTaskDone,
          title: 'Delivery Arrived',
          description:
              'You have reached the customer drop-off point. Mark the task completed when done.',
          navigateLabel: 'Arrived at drop-off',
          confirmLabel: 'Mark delivery completed',
          isCompleted: false,
        );
      }

      if (booking.status == 'completed') {
        return const _TaskStageInfo(
          stage: RiderTaskStage.deliveryTaskDone,
          title: 'Delivery Completed',
          description: 'This delivery has been completed successfully.',
          navigateLabel: 'Delivery completed',
          confirmLabel: 'Delivery completed',
          isCompleted: true,
        );
      }
    }

    return const _TaskStageInfo(
      stage: RiderTaskStage.goToPickup,
      title: 'Task In Progress',
      description: 'Follow the active task steps.',
      navigateLabel: 'Continue',
      confirmLabel: 'Confirm',
      isCompleted: false,
    );
  }

  static Future<void> _makePhoneCall(String phoneNumber) async {
    final trimmed = phoneNumber.trim();
    if (trimmed.isEmpty) return;

    final uri = Uri.parse('tel:$trimmed');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> _openDirectionsForStage({
    required BookingModel booking,
    required RiderTaskStage stage,
    required bool isPickupTask,
    required bool isDeliveryTask,
  }) async {
    double? latitude;
    double? longitude;
    String fallbackAddress = '';

    if (isPickupTask) {
      if (stage == RiderTaskStage.goToPickup) {
        latitude = booking.pickupLatitude;
        longitude = booking.pickupLongitude;
        fallbackAddress = booking.pickupAddress;
      } else {
        latitude = booking.laundrySnapshotLatitude;
        longitude = booking.laundrySnapshotLongitude;
        fallbackAddress = booking.laundrySnapshotAddressLine ?? '';
      }
    } else if (isDeliveryTask) {
      if (stage == RiderTaskStage.goToPickup) {
        latitude = booking.laundrySnapshotLatitude;
        longitude = booking.laundrySnapshotLongitude;
        fallbackAddress = booking.laundrySnapshotAddressLine ?? '';
      } else {
        latitude = booking.deliveryLatitude;
        longitude = booking.deliveryLongitude;
        fallbackAddress = booking.customerAddress;
      }
    }

    if (latitude == null || longitude == null) {
      final encodedDestination = Uri.encodeComponent(fallbackAddress);
      final fallbackUri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$encodedDestination',
      );
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      return;
    }

    final googleMapsUri = Uri.parse('google.navigation:q=$latitude,$longitude');
    final fallbackUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
    );

    if (await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> _confirmStageArrival({
    required BookingModel booking,
    required RiderTaskStage stage,
    required bool isPickupTask,
    required bool isDeliveryTask,
    required DateTime? deliveryPickupArrivedAt,
  }) async {
    final bookingRef = FirebaseFirestore.instance
        .collection('bookings')
        .doc(booking.id);

    final Map<String, dynamic> update = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (isPickupTask) {
      if (stage == RiderTaskStage.goToPickup) {
        update['status'] = 'arrived_at_pickup';
        update['timeline.arrivedAtPickupAt'] = FieldValue.serverTimestamp();
      } else if (stage == RiderTaskStage.goToDropoff) {
        update['status'] = 'arrived_at_laundry';
        update['timeline.arrivedAtLaundryAt'] = FieldValue.serverTimestamp();
      } else {
        return;
      }
    } else if (isDeliveryTask) {
      if (booking.status == 'delivery_in_progress' &&
          deliveryPickupArrivedAt == null) {
        update['timeline.deliveryPickupArrivedAt'] =
            FieldValue.serverTimestamp();
      } else if (booking.status == 'delivery_in_progress' &&
          deliveryPickupArrivedAt != null) {
        update['status'] = 'completed';
        update['timeline.arrivedAtCustomerAt'] = FieldValue.serverTimestamp();
        update['timeline.completedAt'] = FieldValue.serverTimestamp();
        update['deliveryRider.deliveredAt'] = FieldValue.serverTimestamp();
      } else if (booking.status == 'arrived_at_customer') {
        update['status'] = 'completed';
        update['timeline.completedAt'] = FieldValue.serverTimestamp();
        update['deliveryRider.deliveredAt'] = FieldValue.serverTimestamp();
      } else {
        return;
      }
    } else {
      return;
    }

    await bookingRef.update(update);
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

enum RiderTaskStage {
  goToPickup,
  goToDropoff,
  pickupTaskDone,
  deliveryTaskDone,
}

class _TaskStageInfo {
  final RiderTaskStage stage;
  final String title;
  final String description;
  final String navigateLabel;
  final String confirmLabel;
  final bool isCompleted;

  const _TaskStageInfo({
    required this.stage,
    required this.title,
    required this.description,
    required this.navigateLabel,
    required this.confirmLabel,
    required this.isCompleted,
  });
}

class _ParticipantContactCard extends StatelessWidget {
  final String name;
  final String phone;
  final String photoUrl;
  final IconData fallbackIcon;
  final String description;
  final VoidCallback onCall;
  final VoidCallback onChat;

  const _ParticipantContactCard({
    required this.name,
    required this.phone,
    required this.photoUrl,
    required this.fallbackIcon,
    required this.description,
    required this.onCall,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Text(
            description,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFFFEEF5),
                backgroundImage: photoUrl.trim().isNotEmpty
                    ? NetworkImage(photoUrl)
                    : null,
                child: photoUrl.trim().isEmpty
                    ? Icon(
                        fallbackIcon,
                        color: const Color(0xFFFF5B8A),
                        size: 28,
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.trim().isEmpty ? 'Unknown' : name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone.trim().isEmpty ? 'No phone number' : phone,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onCall,
                            icon: const Icon(Icons.call_outlined),
                            label: const Text('Call'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              foregroundColor: const Color(0xFFFF5B8A),
                              side: const BorderSide(color: Color(0xFFFF5B8A)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: onChat,
                            icon: const Icon(Icons.chat_bubble_outline_rounded),
                            label: const Text('Chat'),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              minimumSize: const Size.fromHeight(46),
                              backgroundColor: const Color(0xFFFF5B8A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DestinationSummaryCard extends StatelessWidget {
  final bool isPickupTask;
  final bool isDeliveryTask;
  final BookingModel booking;
  final DateTime? deliveryPickupArrivedAt;

  const _DestinationSummaryCard({
    required this.isPickupTask,
    required this.isDeliveryTask,
    required this.booking,
    required this.deliveryPickupArrivedAt,
  });

  @override
  Widget build(BuildContext context) {
    late final String firstPointLabel;
    late final String firstPointValue;
    late final String secondPointLabel;
    late final String secondPointValue;

    if (isPickupTask) {
      firstPointLabel = 'Pickup Point';
      firstPointValue = booking.pickupAddress;
      secondPointLabel = 'Laundry Drop-off';
      secondPointValue =
          booking.laundrySnapshotAddressLine?.trim().isNotEmpty == true
          ? booking.laundrySnapshotAddressLine!
          : (booking.laundrySnapshotName?.trim().isNotEmpty == true
                ? booking.laundrySnapshotName!
                : 'Laundry address not available');
    } else if (isDeliveryTask) {
      firstPointLabel = deliveryPickupArrivedAt == null
          ? 'Pickup Point'
          : 'Drop-off Point';
      firstPointValue = deliveryPickupArrivedAt == null
          ? (booking.laundrySnapshotAddressLine?.trim().isNotEmpty == true
                ? booking.laundrySnapshotAddressLine!
                : (booking.laundrySnapshotName?.trim().isNotEmpty == true
                      ? booking.laundrySnapshotName!
                      : 'Laundry address not available'))
          : booking.customerAddress;

      secondPointLabel = deliveryPickupArrivedAt == null
          ? 'Customer Drop-off'
          : 'Customer';
      secondPointValue = booking.customerAddress;
    } else {
      firstPointLabel = 'Pickup Point';
      firstPointValue = booking.pickupAddress;
      secondPointLabel = 'Drop-off Point';
      secondPointValue = booking.customerAddress;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.location_on_outlined,
            label: firstPointLabel,
            value: firstPointValue,
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.outlined_flag_rounded,
            label: secondPointLabel,
            value: secondPointValue,
          ),
        ],
      ),
    );
  }
}

class _StageCard extends StatefulWidget {
  final String title;
  final String description;
  final String primaryButtonText;
  final String secondaryButtonText;
  final FutureOr<void> Function() onNavigate;
  final FutureOr<void> Function() onConfirm;
  final bool isActionComplete;

  const _StageCard({
    required this.title,
    required this.description,
    required this.primaryButtonText,
    required this.secondaryButtonText,
    required this.onNavigate,
    required this.onConfirm,
    required this.isActionComplete,
  });

  @override
  State<_StageCard> createState() => _StageCardState();
}

class _StageCardState extends State<_StageCard> {
  bool _navigating = false;
  bool _confirming = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.isActionComplete || _navigating || _confirming
                  ? null
                  : () async {
                      setState(() => _navigating = true);
                      try {
                        await widget.onNavigate();
                      } finally {
                        if (mounted) setState(() => _navigating = false);
                      }
                    },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                foregroundColor: const Color(0xFFFF5B8A),
                side: const BorderSide(color: Color(0xFFFF5B8A)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _navigating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      widget.primaryButtonText,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          _SlideToConfirmButton(
            label: widget.secondaryButtonText,
            isLoading: _confirming,
            isDisabled: widget.isActionComplete || _navigating || _confirming,
            onConfirmed: () async {
              setState(() => _confirming = true);
              try {
                await widget.onConfirm();
              } finally {
                if (mounted) {
                  setState(() => _confirming = false);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SlideToConfirmButton extends StatefulWidget {
  final String label;
  final bool isLoading;
  final bool isDisabled;
  final Future<void> Function() onConfirmed;

  const _SlideToConfirmButton({
    required this.label,
    required this.isLoading,
    required this.isDisabled,
    required this.onConfirmed,
  });

  @override
  State<_SlideToConfirmButton> createState() => _SlideToConfirmButtonState();
}

class _SlideToConfirmButtonState extends State<_SlideToConfirmButton> {
  double _dragDx = 0;

  @override
  void didUpdateWidget(covariant _SlideToConfirmButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading || widget.isDisabled) {
      _dragDx = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double cardHeight = 58;
        const double knobSize = 44;
        const double horizontalPadding = 8;

        final double maxTravel =
            constraints.maxWidth - knobSize - (horizontalPadding * 2);

        final double knobLeft = _dragDx.clamp(0.0, maxTravel);

        Future<void> handleDragEnd() async {
          if (widget.isDisabled || widget.isLoading) return;

          final bool shouldConfirm = knobLeft >= maxTravel * 0.72;

          if (!shouldConfirm) {
            setState(() => _dragDx = 0);
            return;
          }

          setState(() => _dragDx = maxTravel);

          await widget.onConfirmed();

          if (mounted) {
            setState(() => _dragDx = 0);
          }
        }

        return Container(
          height: cardHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.isDisabled
                ? const Color(0xFFE9E9EE)
                : const Color(0xFF3FC37A),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            children: [
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: widget.isLoading ? 0.55 : 1,
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.isDisabled
                          ? const Color(0xFF8B8B95)
                          : Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: horizontalPadding + knobLeft,
                top: 7,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate:
                      (widget.isDisabled || widget.isLoading)
                      ? null
                      : (details) {
                          setState(() {
                            _dragDx = (_dragDx + details.delta.dx).clamp(
                              0.0,
                              maxTravel,
                            );
                          });
                        },
                  onHorizontalDragEnd: (widget.isDisabled || widget.isLoading)
                      ? null
                      : (_) async {
                          await handleDragEnd();
                        },
                  child: Container(
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      color: widget.isDisabled
                          ? Colors.white.withOpacity(0.65)
                          : Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: widget.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(11),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.keyboard_double_arrow_right_rounded,
                            color: widget.isDisabled
                                ? const Color(0xFF8B8B95)
                                : Colors.white,
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFFFF5B8A)),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label\n',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
