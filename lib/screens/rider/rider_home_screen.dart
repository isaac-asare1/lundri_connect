import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/booking_model.dart';
import '../../models/rider_model.dart';

class RiderHomeScreen extends StatelessWidget {
  const RiderHomeScreen({super.key});

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

                return Column(
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
                                await _updateRiderAvailability(
                                  riderId: rider.id,
                                  goOnline: goOnline,
                                );
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
                                                'Request accepted successfully.',
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                      }
                                    },
                                    onReject: () async {
                                      await _rejectRequest(
                                        booking: requests[index],
                                        riderId: rider.id,
                                      );

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Request rejected successfully.',
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

  static Future<void> _updateRiderAvailability({
    required String riderId,
    required bool goOnline,
  }) async {
    final Map<String, dynamic> updateData = {
      'business.isOnline': goOnline,
      'business.availabilityStatus': goOnline ? 'available' : 'offline',
      'business.acceptingAssignments': goOnline,
      'timestamps.updatedAt': FieldValue.serverTimestamp(),
      'timestamps.lastSeen': FieldValue.serverTimestamp(),
    };

    if (goOnline) {
      final _ResolvedLocation location = await _fetchCurrentLocation();

      updateData.addAll({
        'location.latitude': location.latitude,
        'location.longitude': location.longitude,
        'location.addressLine': location.addressLine,
        'location.lastLocationUpdatedAt': FieldValue.serverTimestamp(),
      });
    }

    await FirebaseFirestore.instance
        .collection('riders')
        .doc(riderId)
        .update(updateData);
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

  static Future<void> _acceptRequest({
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

    await bookingRef.update({
      'status': isPickupRequest ? 'pickup_started' : 'delivery_in_progress',
      'updatedAt': FieldValue.serverTimestamp(),
      if (isPickupRequest)
        'timeline.pickupStartedAt': FieldValue.serverTimestamp(),
      if (isDeliveryRequest)
        'timeline.deliveryStartedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _rejectRequest({
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

    await bookingRef.update({
      'status': isPickupRequest
          ? 'looking_for_pickup_rider'
          : 'ready_for_dropoff',
      'updatedAt': FieldValue.serverTimestamp(),
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
    final String serviceType = widget.booking.serviceType
        .replaceAll('_', ' ')
        .toUpperCase();

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
                  widget.booking.customerName,
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
            value: widget.booking.pickupAddress,
          ),
          const SizedBox(height: 10),
          _AddressRow(
            icon: Icons.outlined_flag_rounded,
            title: 'Dropoff:',
            value: widget.booking.customerAddress,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isAccepting || _isRejecting
                      ? null
                      : () async {
                          setState(() {
                            _isRejecting = true;
                          });

                          try {
                            await widget.onReject();
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isRejecting = false;
                              });
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isAccepting || _isRejecting
                      ? null
                      : () async {
                          setState(() {
                            _isAccepting = true;
                          });

                          try {
                            await widget.onAccept();
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isAccepting = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFFFF5B8A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isAccepting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Accept Task',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
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
