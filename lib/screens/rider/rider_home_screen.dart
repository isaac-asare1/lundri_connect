import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../models/booking_model.dart';
import '../../models/rider_model.dart';
import 'rider_business_info_screen.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  StreamSubscription<Position>? _locationSubscription;

  final ValueNotifier<bool> _showCompleteProfileCard = ValueNotifier(false);

  final AudioPlayer _requestRingPlayer = AudioPlayer();
  Timer? _requestRingTimer;
  bool _isRinging = false;

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _requestRingTimer?.cancel();
    _requestRingPlayer.dispose();
    _showCompleteProfileCard.dispose();
    super.dispose();
  }

  void _openCompleteProfileCard() {
    _showCompleteProfileCard.value = true;
  }

  void _closeCompleteProfileCard() {
    _showCompleteProfileCard.value = false;
  }

  Future<void> _goToProfileSetup() async {
    _closeCompleteProfileCard();

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RiderProfileSetupScreen()),
    );
  }

  Future<void> _startRiderLocationTracking(String riderId) async {
    await _locationSubscription?.cancel();

    final _ResolvedLocation currentLocation = await _fetchCurrentLocation();

    await _saveRiderLocation(
      riderId: riderId,
      location: currentLocation,
      setOnline: true,
    );

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 200,
    );

    _locationSubscription =
        Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position position) async {
          final GeoFirePoint geoFirePoint = GeoFirePoint(
            GeoPoint(position.latitude, position.longitude),
          );

          await FirebaseFirestore.instance
              .collection('riders')
              .doc(riderId)
              .update({
                'location.geohash': geoFirePoint.geohash,
                'location.geopoint': geoFirePoint.geopoint,
                'location.heading': position.heading,
                'location.lastLocationUpdatedAt': FieldValue.serverTimestamp(),
                'timestamps.updatedAt': FieldValue.serverTimestamp(),
                'timestamps.lastSeen': FieldValue.serverTimestamp(),
              });
        });
  }

  Future<void> _stopRiderLocationTracking(String riderId) async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    await FirebaseFirestore.instance.collection('riders').doc(riderId).update({
      'business.isOnline': false,
      'business.availabilityStatus': 'offline',
      'business.acceptingAssignments': false,
      'location.lastLocationUpdatedAt': FieldValue.serverTimestamp(),
      'timestamps.updatedAt': FieldValue.serverTimestamp(),
      'timestamps.lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> playRequestRing() async {
    if (_isRinging) return;

    _isRinging = true;

    await _requestRingPlayer.stop();
    await _requestRingPlayer.setReleaseMode(ReleaseMode.loop);
    await _requestRingPlayer.play(AssetSource('sounds/request_ring.mp3'));

    _requestRingTimer?.cancel();
    _requestRingTimer = Timer(const Duration(minutes: 1), () async {
      await stopRequestRing();
    });
  }

  Future<void> stopRequestRing() async {
    if (!_isRinging) return;

    _requestRingTimer?.cancel();
    _requestRingTimer = null;

    await _requestRingPlayer.stop();
    await _requestRingPlayer.setReleaseMode(ReleaseMode.release);

    _isRinging = false;
  }

  static Future<void> _saveRiderLocation({
    required String riderId,
    required _ResolvedLocation location,
    required bool setOnline,
  }) async {
    final GeoFirePoint geoFirePoint = GeoFirePoint(
      GeoPoint(location.latitude, location.longitude),
    );

    await FirebaseFirestore.instance.collection('riders').doc(riderId).update({
      if (setOnline) 'business.isOnline': true,
      if (setOnline) 'business.availabilityStatus': 'available',
      if (setOnline) 'business.acceptingAssignments': true,
      'location.geohash': geoFirePoint.geohash,
      'location.geopoint': geoFirePoint.geopoint,
      'location.addressLine': location.addressLine,
      'location.lastLocationUpdatedAt': FieldValue.serverTimestamp(),
      'timestamps.updatedAt': FieldValue.serverTimestamp(),
      'timestamps.lastSeen': FieldValue.serverTimestamp(),
    });
  }

  static Future<_ResolvedLocation> _fetchCurrentLocation() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location services are turned off.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Please enable it in settings.',
      );
    }

    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String addressLine = '';

    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final parts = <String>[
          if ((place.street ?? '').trim().isNotEmpty) place.street!.trim(),
          if ((place.subLocality ?? '').trim().isNotEmpty)
            place.subLocality!.trim(),
          if ((place.locality ?? '').trim().isNotEmpty) place.locality!.trim(),
          if ((place.administrativeArea ?? '').trim().isNotEmpty)
            place.administrativeArea!.trim(),
          if ((place.country ?? '').trim().isNotEmpty) place.country!.trim(),
        ];

        addressLine = parts.join(', ');
      }
    } catch (_) {
      addressLine = '';
    }

    return _ResolvedLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      addressLine: addressLine,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F4F6),
        body: SafeArea(
          child: Center(
            child: Text(
              'You need to sign in again.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3440),
              ),
            ),
          ),
        ),
      );
    }

    final riderStream = FirebaseFirestore.instance
        .collection('riders')
        .doc(currentUser.uid)
        .snapshots();

    final bookingsStream = FirebaseFirestore.instance
        .collection('bookings')
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4F6),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: riderStream,
          builder: (context, riderSnapshot) {
            if (riderSnapshot.connectionState == ConnectionState.waiting) {
              return const _CenteredLoader(message: 'Loading rider profile...');
            }

            if (riderSnapshot.hasError) {
              return _ErrorView(
                message:
                    'Failed to load rider profile.\n${riderSnapshot.error}',
              );
            }

            if (!riderSnapshot.hasData || !riderSnapshot.data!.exists) {
              return const _ErrorView(message: 'Rider profile not found.');
            }

            final rider = RiderModel.fromDocument(riderSnapshot.data!);

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: bookingsStream,
              builder: (context, bookingsSnapshot) {
                if (bookingsSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const _CenteredLoader(
                    message: 'Loading new requests...',
                  );
                }

                if (bookingsSnapshot.hasError) {
                  return _ErrorView(
                    message:
                        'Failed to load booking requests.\n${bookingsSnapshot.error}',
                  );
                }

                final docs =
                    bookingsSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[];

                final requests =
                    docs
                        .map((doc) => BookingModel.fromMap(doc.data(), doc.id))
                        .where(
                          (booking) => _isNewRequestForRider(booking, rider.id),
                        )
                        .toList()
                      ..sort((a, b) {
                        final aTime =
                            a.updatedAt ?? a.createdAt ?? DateTime(2000);
                        final bTime =
                            b.updatedAt ?? b.createdAt ?? DateTime(2000);
                        return bTime.compareTo(aTime);
                      });

                if (requests.isNotEmpty) {
                  playRequestRing();
                }

                return Stack(
                  children: [
                    Column(
                      children: [
                        _buildHeader(context),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SwipeOnlineCard(
                                  isOnline: rider.isOnline,
                                  onChanged: (goOnline) async {
                                    if (!rider.isProfileCompleted && goOnline) {
                                      _openCompleteProfileCard();

                                      ScaffoldMessenger.of(context)
                                        ..hideCurrentSnackBar()
                                        ..showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Complete your profile before going online.',
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      return;
                                    }

                                    if (goOnline) {
                                      await _startRiderLocationTracking(
                                        rider.id,
                                      );
                                    } else {
                                      await _stopRiderLocationTracking(
                                        rider.id,
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _QuickStatCard(
                                        icon: Icons.assignment_outlined,
                                        iconColor: const Color(0xFFFF5B8A),
                                        value: '${requests.length}',
                                        label: 'New Requests',
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: _QuickStatCard(
                                        icon: Icons.wifi_tethering_rounded,
                                        iconColor: const Color(0xFFFF5B8A),
                                        value: rider.isOnline ? 'Yes' : 'No',
                                        label: 'Online',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 22),
                                const Text(
                                  'New Requests',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2A2F3A),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                if (requests.isEmpty)
                                  const _EmptyRequestsCard()
                                else
                                  ...List.generate(
                                    requests.length,
                                    (index) => Padding(
                                      padding: EdgeInsets.only(
                                        bottom: index == requests.length - 1
                                            ? 0
                                            : 14,
                                      ),
                                      child: _RiderRequestCard(
                                        booking: requests[index],
                                        onAccept: () async {
                                          await _acceptRequest(
                                            booking: requests[index],
                                            riderId: rider.id,
                                          );

                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Order accepted successfully.',
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                          }
                                        },
                                        onReject: () async {
                                          final result =
                                              await showModalBottomSheet<
                                                _CancelOrderResult
                                              >(
                                                context: context,
                                                isScrollControlled: true,
                                                backgroundColor:
                                                    Colors.transparent,
                                                builder: (_) =>
                                                    const _CancelOrderSheet(),
                                              );

                                          if (result == null) return;

                                          await _rejectRequest(
                                            booking: requests[index],
                                            riderId: rider.id,
                                            reason: result.reason,
                                            note: result.note,
                                          );

                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                              ..hideCurrentSnackBar()
                                              ..showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Order rejected successfully.',
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    ValueListenableBuilder<bool>(
                      valueListenable: _showCompleteProfileCard,
                      builder: (context, showCard, _) {
                        if (!showCard) return const SizedBox.shrink();

                        return _BlurredCompleteProfileOverlay(
                          onClose: _closeCompleteProfileCard,
                          onCompleteProfile: _goToProfileSetup,
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  static Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF2D3440),
              size: 20,
            ),
          ),
          const SizedBox(width: 2),
          const Text(
            'Rider Home',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3440),
            ),
          ),
        ],
      ),
    );
  }

  static bool _isNewRequestForRider(BookingModel booking, String riderId) {
    final bool isPickupRequest =
        booking.status == 'looking_for_pickup_rider' &&
        booking.pickupRiderId == riderId;

    final bool isDeliveryRequest =
        booking.status == 'ready_for_dropoff' &&
        booking.deliveryRiderId == riderId;

    return isPickupRequest || isDeliveryRequest;
  }

  Future<void> _acceptRequest({
    required BookingModel booking,
    required String riderId,
  }) async {
    final bookingRef = FirebaseFirestore.instance
        .collection('bookings')
        .doc(booking.id);

    final bool isPickupRequest =
        booking.pickupRiderId == riderId &&
        booking.status == 'looking_for_pickup_rider';

    final bool isDeliveryRequest =
        booking.deliveryRiderId == riderId &&
        booking.status == 'ready_for_dropoff';

    if (!isPickupRequest && !isDeliveryRequest) return;

    await stopRequestRing();

    await bookingRef.update({
      'status': isPickupRequest ? 'pickup_started' : 'delivery_in_progress',
      'updatedAt': FieldValue.serverTimestamp(),
      'riderRejection': null,
      if (isPickupRequest)
        'timeline.pickupStartedAt': FieldValue.serverTimestamp(),
      if (isDeliveryRequest)
        'timeline.deliveryStartedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _rejectRequest({
    required BookingModel booking,
    required String riderId,
    required String reason,
    required String note,
  }) async {
    final bookingRef = FirebaseFirestore.instance
        .collection('bookings')
        .doc(booking.id);

    final bool isPickupRequest =
        booking.pickupRiderId == riderId &&
        booking.status == 'looking_for_pickup_rider';

    final bool isDeliveryRequest =
        booking.deliveryRiderId == riderId &&
        booking.status == 'ready_for_dropoff';

    if (!isPickupRequest && !isDeliveryRequest) return;

    await stopRequestRing();

    await bookingRef.update({
      'status': isPickupRequest
          ? 'looking_for_pickup_rider'
          : 'ready_for_dropoff',
      'updatedAt': FieldValue.serverTimestamp(),
      'riderRejection': {
        'riderId': riderId,
        'reason': reason,
        'note': note,
        'taskType': isPickupRequest ? 'pickup' : 'delivery',
        'rejectedAt': FieldValue.serverTimestamp(),
      },
      if (isPickupRequest)
        'pickupRider': {
          'riderId': null,
          'fullName': null,
          'phoneNumber': null,
          'photoUrl': null,
          'vehicleType': null,
          'plateNumber': null,
          'assignedAt': null,
          'pickedUpAt': null,
        },
      if (isDeliveryRequest)
        'deliveryRider': {
          'riderId': null,
          'fullName': null,
          'phoneNumber': null,
          'photoUrl': null,
          'vehicleType': null,
          'plateNumber': null,
          'assignedAt': null,
          'deliveredAt': null,
        },
    });
  }
}

class _BlurredCompleteProfileOverlay extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onCompleteProfile;

  const _BlurredCompleteProfileOverlay({
    required this.onClose,
    required this.onCompleteProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: 1,
        child: Stack(
          children: [
            GestureDetector(
              onTap: onClose,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(color: Colors.black.withOpacity(0.18)),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _CompleteProfileCard(
                  onTap: onCompleteProfile,
                  onClose: onClose,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompleteProfileCard extends StatelessWidget {
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _CompleteProfileCard({required this.onTap, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7FB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Color(0xFF2D3440),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5B8A).withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.person_add_alt_1_rounded,
                color: Color(0xFFFF5B8A),
                size: 27,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Complete your rider profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2D3440),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your profile photo, Ghana Card, vehicle details, phone verification, and location before going online.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Color(0xFF7C8493),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(
                  'Complete Profile',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFFF5B8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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

class _ResolvedLocation {
  final double latitude;
  final double longitude;
  final String addressLine;

  const _ResolvedLocation({
    required this.latitude,
    required this.longitude,
    required this.addressLine,
  });
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _QuickStatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D3440),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7C8493),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF7C8493),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _EmptyRequestsCard extends StatelessWidget {
  const _EmptyRequestsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 38,
            color: Color(0xFF9AA3AF),
          ),
          SizedBox(height: 12),
          Text(
            'No new requests yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3440),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'When a laundry sends you a new request, it will show here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF7C8493),
            ),
          ),
        ],
      ),
    );
  }
}

class _CenteredLoader extends StatelessWidget {
  final String message;

  const _CenteredLoader({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF7C8493),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiderRequestCard extends StatefulWidget {
  final BookingModel booking;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  const _RiderRequestCard({
    required this.booking,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<_RiderRequestCard> createState() => _RiderRequestCardState();
}

class _RiderRequestCardState extends State<_RiderRequestCard> {
  bool _isAccepting = false;
  bool _isRejecting = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    final String serviceType = booking.serviceType
        .replaceAll('_', ' ')
        .toUpperCase();

    final bool isPickupRequest = booking.status == 'looking_for_pickup_rider';

    final bool isDeliveryRequest = booking.status == 'ready_for_dropoff';

    final String laundryAddress =
        booking.laundrySnapshotAddressLine?.trim().isNotEmpty == true
        ? booking.laundrySnapshotAddressLine!.trim()
        : booking.laundrySnapshotName?.trim().isNotEmpty == true
        ? booking.laundrySnapshotName!.trim()
        : 'Laundry address not available';

    final String customerAddress = booking.customerAddress.trim().isNotEmpty
        ? booking.customerAddress.trim()
        : 'Customer address not available';

    final String pickupAddress;
    final String dropoffAddress;

    if (isDeliveryRequest) {
      pickupAddress = laundryAddress;
      dropoffAddress = customerAddress;
    } else if (isPickupRequest) {
      pickupAddress = customerAddress;
      dropoffAddress = laundryAddress;
    } else {
      pickupAddress = customerAddress;
      dropoffAddress = laundryAddress;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 22,
            offset: Offset(0, 10),
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
                  booking.customerName.trim().isEmpty
                      ? 'Customer'
                      : booking.customerName.trim(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3440),
                  ),
                ),
              ),
              const _PendingChip(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            serviceType,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFF5B8A),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          _AddressRow(
            icon: Icons.location_on_outlined,
            title: 'Pickup:',
            value: pickupAddress,
          ),
          const SizedBox(height: 10),
          _AddressRow(
            icon: Icons.outlined_flag_rounded,
            title: 'Dropoff:',
            value: dropoffAddress,
          ),
          const SizedBox(height: 18),
          OutlinedButton(
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
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: Color(0xFFFF5B8A)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isRejecting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Reject',
                    style: TextStyle(
                      color: Color(0xFFFF5B8A),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          _SlideAcceptOrderButton(
            isLoading: _isAccepting,
            enabled: !_isAccepting && !_isRejecting,
            onAccepted: () async {
              setState(() => _isAccepting = true);

              try {
                await widget.onAccept();
              } finally {
                if (mounted) {
                  setState(() => _isAccepting = false);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SlideAcceptOrderButton extends StatefulWidget {
  final bool isLoading;
  final bool enabled;
  final Future<void> Function() onAccepted;

  const _SlideAcceptOrderButton({
    required this.isLoading,
    required this.enabled,
    required this.onAccepted,
  });

  @override
  State<_SlideAcceptOrderButton> createState() =>
      _SlideAcceptOrderButtonState();
}

class _SlideAcceptOrderButtonState extends State<_SlideAcceptOrderButton> {
  double _dragDx = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double cardHeight = 64;
        const double knobSize = 48;
        const double horizontalPadding = 8;

        final double maxTravel =
            constraints.maxWidth - knobSize - (horizontalPadding * 2);

        final double knobLeft = _dragDx.clamp(0.0, maxTravel);

        return Container(
          height: cardHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFFF5B8A),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            children: [
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: widget.isLoading ? 0.55 : 1,
                  child: const Text(
                    'Accept order',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: horizontalPadding + knobLeft,
                top: 8,
                child: GestureDetector(
                  onHorizontalDragUpdate: widget.enabled && !widget.isLoading
                      ? (details) {
                          setState(() {
                            _dragDx += details.delta.dx;
                          });
                        }
                      : null,
                  onHorizontalDragEnd: widget.enabled && !widget.isLoading
                      ? (_) async {
                          final bool shouldAccept = knobLeft > maxTravel * 0.70;

                          setState(() => _dragDx = 0);

                          if (!shouldAccept) return;

                          await widget.onAccepted();
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: widget.isLoading
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
                            size: 26,
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

class _SwipeOnlineCard extends StatefulWidget {
  final bool isOnline;
  final Future<void> Function(bool goOnline) onChanged;

  const _SwipeOnlineCard({required this.isOnline, required this.onChanged});

  @override
  State<_SwipeOnlineCard> createState() => _SwipeOnlineCardState();
}

class _SwipeOnlineCardState extends State<_SwipeOnlineCard> {
  double _dragDx = 0;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final bool isOnline = widget.isOnline;

    return LayoutBuilder(
      builder: (context, constraints) {
        const double cardHeight = 68;
        const double knobSize = 48;
        const double horizontalPadding = 8;

        final double maxTravel =
            constraints.maxWidth - knobSize - (horizontalPadding * 2);

        final double restingLeft = isOnline ? maxTravel : 0;
        final double knobLeft = (restingLeft + _dragDx).clamp(0.0, maxTravel);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: cardHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isOnline ? const Color(0xFF121433) : const Color(0xFF3FC37A),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Stack(
            children: [
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _isSaving ? 0.55 : 1,
                  child: Text(
                    isOnline ? 'Go offline' : 'Go online',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: horizontalPadding + knobLeft,
                top: 10,
                child: GestureDetector(
                  onHorizontalDragUpdate: _isSaving
                      ? null
                      : (details) {
                          setState(() {
                            _dragDx += details.delta.dx;
                          });
                        },
                  onHorizontalDragEnd: _isSaving
                      ? null
                      : (_) async {
                          final bool shouldToggle = isOnline
                              ? knobLeft < maxTravel * 0.40
                              : knobLeft > maxTravel * 0.60;

                          setState(() {
                            _dragDx = 0;
                          });

                          if (!shouldToggle) return;

                          setState(() {
                            _isSaving = true;
                          });

                          try {
                            await widget.onChanged(!isOnline);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceFirst(
                                        'Exception: ',
                                        '',
                                      ),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isSaving = false;
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
                    child: _isSaving
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

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _AddressRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: const Color(0xFF7B8492)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$title ',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3440),
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7B8492),
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

class _PendingChip extends StatelessWidget {
  const _PendingChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'pending',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFFF0A229),
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
    'Too far from my location',
    'I am currently unavailable',
    'Vehicle issue',
    'Pickup cannot be completed',
    'Delivery cannot be completed',
    'Other',
  ];

  String _selectedReason = 'I am currently unavailable';

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
                  color: Color(0xFF2D3440),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select a reason and add a short note.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: Color(0xFF7C8493),
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
                            ? const Color(0xFFFF5B8A).withOpacity(0.12)
                            : const Color(0xFFF6F7FB),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF5B8A)
                              : Colors.black.withOpacity(0.06),
                        ),
                      ),
                      child: Text(
                        reason,
                        style: TextStyle(
                          fontSize: 12.8,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? const Color(0xFFFF5B8A)
                              : const Color(0xFF2D3440),
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
                      color: Color(0xFFFF5B8A),
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
                        foregroundColor: const Color(0xFF2D3440),
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
