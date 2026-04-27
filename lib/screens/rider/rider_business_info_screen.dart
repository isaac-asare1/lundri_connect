// import 'dart:io';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:lundri_connect/screens/laundry/location_picker.dart';
// import 'package:provider/provider.dart';

// import '../../providers/user_provider.dart';

// class PickedLocationResult {
//   final double latitude;
//   final double longitude;
//   final String addressLine;
//   final String subtitle;
//   final String serviceType;

//   const PickedLocationResult({
//     required this.latitude,
//     required this.longitude,
//     required this.addressLine,
//     required this.subtitle,
//     required this.serviceType,
//   });
// }

// class RiderProfileSetupScreen extends StatefulWidget {
//   const RiderProfileSetupScreen({super.key});

//   @override
//   State<RiderProfileSetupScreen> createState() =>
//       _RiderProfileSetupScreenState();
// }

// class _RiderProfileSetupScreenState extends State<RiderProfileSetupScreen> {
//   final _formKey = GlobalKey<FormState>();

//   final _firestore = FirebaseFirestore.instance;
//   final _storage = FirebaseStorage.instance;
//   final _auth = fb_auth.FirebaseAuth.instance;
//   final _picker = ImagePicker();

//   late final TextEditingController _fullNameController;
//   late final TextEditingController _emailController;
//   late final TextEditingController _phoneController;
//   late final TextEditingController _whatsappController;
//   late final TextEditingController _otpController;
//   late final TextEditingController _addressController;
//   late final TextEditingController _digitalAddressController;
//   late final TextEditingController _landmarkController;
//   late final TextEditingController _ghanaCardNumberController;
//   late final TextEditingController _vehicleTypeController;
//   late final TextEditingController _vehicleMakeController;
//   late final TextEditingController _vehicleColorController;
//   late final TextEditingController _plateNumberController;

//   bool _loading = true;
//   bool _saving = false;
//   bool _uploading = false;
//   bool _sendingOtp = false;
//   bool _verifyingOtp = false;
//   bool _phoneVerified = false;

//   String _profilePhotoUrl = '';
//   String _ghanaCardFrontUrl = '';
//   String _ghanaCardBackUrl = '';
//   String _verificationId = '';

//   double? _selectedLatitude;
//   double? _selectedLongitude;

//   String get _riderId {
//     final user = context.read<UserProvider>().currentUser;
//     return user?.id ?? _auth.currentUser?.uid ?? '';
//   }

//   @override
//   void initState() {
//     super.initState();

//     _fullNameController = TextEditingController();
//     _emailController = TextEditingController();
//     _phoneController = TextEditingController();
//     _whatsappController = TextEditingController();
//     _otpController = TextEditingController();
//     _addressController = TextEditingController();
//     _digitalAddressController = TextEditingController();
//     _landmarkController = TextEditingController();
//     _ghanaCardNumberController = TextEditingController();
//     _vehicleTypeController = TextEditingController();
//     _vehicleMakeController = TextEditingController();
//     _vehicleColorController = TextEditingController();
//     _plateNumberController = TextEditingController();

//     _loadRiderData();
//   }

//   @override
//   void dispose() {
//     _fullNameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _whatsappController.dispose();
//     _otpController.dispose();
//     _addressController.dispose();
//     _digitalAddressController.dispose();
//     _landmarkController.dispose();
//     _ghanaCardNumberController.dispose();
//     _vehicleTypeController.dispose();
//     _vehicleMakeController.dispose();
//     _vehicleColorController.dispose();
//     _plateNumberController.dispose();
//     super.dispose();
//   }

//   Future<void> _loadRiderData() async {
//     if (_riderId.isEmpty) {
//       setState(() => _loading = false);
//       return;
//     }

//     try {
//       final doc = await _firestore.collection('riders').doc(_riderId).get();
//       final data = doc.data() ?? {};

//       final profile = _asMap(data['profile']);
//       final contact = _asMap(data['contact']);
//       final location = _asMap(data['location']);
//       final vehicle = _asMap(data['vehicle']);
//       final verification = _asMap(data['verification']);
//       final ghanaCard = _asMap(verification['ghanaCard']);

//       _fullNameController.text = _readString(profile['fullName']);
//       _emailController.text = _readString(contact['email']);
//       _phoneController.text = _readString(contact['phoneNumber']);
//       _whatsappController.text = _readString(contact['whatsappNumber']);

//       _addressController.text = _readString(location['addressLine']);
//       _digitalAddressController.text = _readString(location['digitalAddress']);
//       _landmarkController.text = _readString(location['landmark']);

//       _vehicleTypeController.text = _readString(vehicle['type']);
//       _vehicleMakeController.text = _readString(vehicle['make']);
//       _vehicleColorController.text = _readString(vehicle['color']);
//       _plateNumberController.text = _readString(vehicle['plateNumber']);

//       _ghanaCardNumberController.text = _readString(ghanaCard['number']);

//       _profilePhotoUrl = _readString(profile['photoUrl']);
//       _ghanaCardFrontUrl = _readString(ghanaCard['frontImageUrl']);
//       _ghanaCardBackUrl = _readString(ghanaCard['backImageUrl']);

//       _phoneVerified = _readBool(contact['phoneVerified']);

//       _selectedLatitude =
//           _readDouble(location['latitude']) ?? _readGeoPointLat(location);
//       _selectedLongitude =
//           _readDouble(location['longitude']) ?? _readGeoPointLng(location);
//     } catch (e) {
//       debugPrint('Load rider data error: $e');
//       _showSnackBar('Could not load rider profile');
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }

//   Future<void> _pickAndUploadImage({
//     required String storagePath,
//     required void Function(String url) onUploaded,
//     required String successMessage,
//   }) async {
//     if (_riderId.isEmpty || _uploading) return;

//     try {
//       final picked = await _picker.pickImage(
//         source: ImageSource.gallery,
//         imageQuality: 80,
//         maxWidth: 1200,
//       );

//       if (picked == null) return;

//       setState(() => _uploading = true);

//       final file = File(picked.path);
//       final ref = _storage.ref(storagePath);

//       await ref.putFile(file);
//       final url = await ref.getDownloadURL();

//       onUploaded(url);

//       _showSnackBar(successMessage);
//     } on PlatformException catch (e) {
//       debugPrint('Image picker error: ${e.message}');
//       _showSnackBar('Image picker failed. Restart the app.');
//     } catch (e) {
//       debugPrint('Image upload error: $e');
//       _showSnackBar('Image upload failed');
//     } finally {
//       if (mounted) setState(() => _uploading = false);
//     }
//   }

//   Future<void> _pickProfilePhoto() async {
//     await _pickAndUploadImage(
//       storagePath: 'riders/$_riderId/profile/profile_photo.jpg',
//       successMessage: 'Profile photo added',
//       onUploaded: (url) {
//         setState(() => _profilePhotoUrl = url);
//       },
//     );
//   }

//   Future<void> _pickGhanaCardFront() async {
//     await _pickAndUploadImage(
//       storagePath: 'riders/$_riderId/verification/ghana_card_front.jpg',
//       successMessage: 'Ghana Card front uploaded',
//       onUploaded: (url) {
//         setState(() => _ghanaCardFrontUrl = url);
//       },
//     );
//   }

//   Future<void> _pickGhanaCardBack() async {
//     await _pickAndUploadImage(
//       storagePath: 'riders/$_riderId/verification/ghana_card_back.jpg',
//       successMessage: 'Ghana Card back uploaded',
//       onUploaded: (url) {
//         setState(() => _ghanaCardBackUrl = url);
//       },
//     );
//   }

//   Future<void> _sendOtp() async {
//     final phone = _normalizeGhanaPhone(_phoneController.text);

//     if (phone == null) {
//       _showSnackBar('Enter a valid Ghana phone number');
//       return;
//     }

//     setState(() => _sendingOtp = true);

//     try {
//       await _auth.verifyPhoneNumber(
//         phoneNumber: phone,
//         timeout: const Duration(seconds: 60),
//         verificationCompleted: (credential) async {
//           try {
//             final user = _auth.currentUser;
//             if (user != null) {
//               await user.linkWithCredential(credential).catchError((_) {});
//             }

//             if (!mounted) return;
//             setState(() => _phoneVerified = true);
//             _showSnackBar('Phone number verified');
//           } catch (_) {}
//         },
//         verificationFailed: (e) {
//           debugPrint('OTP verification failed: ${e.code}');
//           _showSnackBar('Could not send OTP');
//         },
//         codeSent: (verificationId, resendToken) {
//           setState(() => _verificationId = verificationId);
//           _showSnackBar('OTP sent');
//         },
//         codeAutoRetrievalTimeout: (verificationId) {
//           _verificationId = verificationId;
//         },
//       );
//     } catch (e) {
//       debugPrint('Send OTP error: $e');
//       _showSnackBar('Could not send OTP');
//     } finally {
//       if (mounted) setState(() => _sendingOtp = false);
//     }
//   }

//   Future<void> _verifyOtp() async {
//     final code = _otpController.text.trim();

//     if (_verificationId.isEmpty) {
//       _showSnackBar('Request OTP first');
//       return;
//     }

//     if (code.length < 6) {
//       _showSnackBar('Enter the 6-digit OTP');
//       return;
//     }

//     setState(() => _verifyingOtp = true);

//     try {
//       final credential = fb_auth.PhoneAuthProvider.credential(
//         verificationId: _verificationId,
//         smsCode: code,
//       );

//       final user = _auth.currentUser;
//       if (user != null) {
//         await user.linkWithCredential(credential).catchError((_) {});
//       }

//       setState(() => _phoneVerified = true);
//       _showSnackBar('Phone number verified');
//     } catch (e) {
//       debugPrint('Verify OTP error: $e');
//       _showSnackBar('Invalid OTP');
//     } finally {
//       if (mounted) setState(() => _verifyingOtp = false);
//     }
//   }

//   Future<void> _openLocationPicker() async {
//     final result = await Navigator.of(context).push<PickedLocationResult>(
//       MaterialPageRoute(
//         builder: (_) =>
//             const GoogleMapLocationPickerScreen(serviceType: 'rider_home'),
//       ),
//     );

//     if (!mounted || result == null) return;

//     setState(() {
//       _addressController.text = result.addressLine;
//       _digitalAddressController.text = result.subtitle;
//       _selectedLatitude = result.latitude;
//       _selectedLongitude = result.longitude;
//     });
//   }

//   Future<void> _save() async {
//     final isValid = _formKey.currentState?.validate() ?? false;
//     if (!isValid || _riderId.isEmpty) return;

//     if (!_phoneVerified) {
//       _showSnackBar('Please verify your phone number');
//       return;
//     }

//     if (_profilePhotoUrl.trim().isEmpty) {
//       _showSnackBar('Please add a profile photo');
//       return;
//     }

//     if (_ghanaCardFrontUrl.trim().isEmpty || _ghanaCardBackUrl.trim().isEmpty) {
//       _showSnackBar('Please upload both sides of your Ghana Card');
//       return;
//     }

//     if (_selectedLatitude == null || _selectedLongitude == null) {
//       _showSnackBar('Please choose your rider location');
//       return;
//     }

//     setState(() => _saving = true);

//     try {
//       final docRef = _firestore.collection('riders').doc(_riderId);
//       final oldSnap = await docRef.get();
//       final oldData = oldSnap.data() ?? {};

//       final oldBusiness = _asMap(oldData['business']);
//       final oldRatings = _asMap(oldData['ratings']);
//       final oldStats = _asMap(oldData['stats']);
//       final oldChat = _asMap(oldData['chat']);
//       final oldTimestamps = _asMap(oldData['timestamps']);

//       final phone =
//           _normalizeGhanaPhone(_phoneController.text) ??
//           _phoneController.text.trim();

//       await docRef.set({
//         'id': _riderId,
//         'role': 'rider',

//         'profile': {
//           'fullName': _fullNameController.text.trim(),
//           'photoUrl': _profilePhotoUrl,
//         },

//         'contact': {
//           'phoneNumber': phone,
//           'email': _emailController.text.trim(),
//           'whatsappNumber': _whatsappController.text.trim(),
//           'phoneVerified': _phoneVerified,
//           'phoneVerifiedAt': FieldValue.serverTimestamp(),
//         },

//         'location': {
//           'addressLine': _addressController.text.trim(),
//           'digitalAddress': _digitalAddressController.text.trim(),
//           'landmark': _landmarkController.text.trim(),
//           'latitude': _selectedLatitude,
//           'longitude': _selectedLongitude,
//           'geopoint': GeoPoint(_selectedLatitude!, _selectedLongitude!),
//           'geohash': null,
//           'lastLocationUpdatedAt': FieldValue.serverTimestamp(),
//         },

//         'business': {
//           ...oldBusiness,
//           'isApproved': oldBusiness['isApproved'] ?? false,
//           'isOnline': oldBusiness['isOnline'] ?? false,
//           'availabilityStatus': oldBusiness['availabilityStatus'] ?? 'offline',
//           'acceptingAssignments': oldBusiness['acceptingAssignments'] ?? false,
//           'maxActiveRequests': oldBusiness['maxActiveRequests'] ?? 2,
//           'currentActiveRequestCount':
//               oldBusiness['currentActiveRequestCount'] ?? 0,
//           'activeRequestIds': oldBusiness['activeRequestIds'] ?? <String>[],
//           'currentLaundryIds': oldBusiness['currentLaundryIds'] ?? <String>[],
//           'currentCustomerIds': oldBusiness['currentCustomerIds'] ?? <String>[],
//         },

//         'vehicle': {
//           'type': _vehicleTypeController.text.trim(),
//           'make': _vehicleMakeController.text.trim(),
//           'color': _vehicleColorController.text.trim(),
//           'plateNumber': _plateNumberController.text.trim().toUpperCase(),
//         },

//         'verification': {
//           'status': 'pending_review',
//           'submittedAt': FieldValue.serverTimestamp(),
//           'ghanaCard': {
//             'number': _ghanaCardNumberController.text.trim(),
//             'frontImageUrl': _ghanaCardFrontUrl,
//             'backImageUrl': _ghanaCardBackUrl,
//           },
//         },

//         'ratings': {
//           'rating': oldRatings['rating'] ?? 0.0,
//           'totalReviews': oldRatings['totalReviews'] ?? 0,
//         },

//         'stats': {
//           'totalRequestsReceived': oldStats['totalRequestsReceived'] ?? 0,
//           'acceptedRequests': oldStats['acceptedRequests'] ?? 0,
//           'rejectedRequests': oldStats['rejectedRequests'] ?? 0,
//           'totalDeliveries': oldStats['totalDeliveries'] ?? 0,
//           'completedDeliveries': oldStats['completedDeliveries'] ?? 0,
//           'cancelledDeliveries': oldStats['cancelledDeliveries'] ?? 0,
//         },

//         'chat': {
//           'lastSeenAt': oldChat['lastSeenAt'],
//           'fcmTokens': oldChat['fcmTokens'] ?? <String, bool>{},
//           'fcmUpdatedAt': oldChat['fcmUpdatedAt'],
//         },

//         'timestamps': {
//           'createdAt':
//               oldTimestamps['createdAt'] ?? FieldValue.serverTimestamp(),
//           'updatedAt': FieldValue.serverTimestamp(),
//           'lastLoginAt':
//               oldTimestamps['lastLoginAt'] ?? FieldValue.serverTimestamp(),
//           'lastSeen': FieldValue.serverTimestamp(),
//         },
//       }, SetOptions(merge: true));

//       if (!mounted) return;

//       _showSnackBar('Rider profile submitted for review');
//       Navigator.pop(context);
//     } catch (e) {
//       debugPrint('Save rider profile error: $e');
//       _showSnackBar('Could not save rider profile');
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) {
//       return const Scaffold(
//         backgroundColor: Color(0xFFF7F9FC),
//         body: Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F9FC),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFF7F9FC),
//         elevation: 0,
//         foregroundColor: const Color(0xFF101828),
//         title: const Text(
//           'Rider Profile Setup',
//           style: TextStyle(fontWeight: FontWeight.w800),
//         ),
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 _HeaderPhoto(
//                   imageUrl: _profilePhotoUrl,
//                   loading: _uploading,
//                   emptyText: 'Add rider profile',
//                   buttonText: 'Change profile',
//                   onTap: _pickProfilePhoto,
//                 ),

//                 const SizedBox(height: 28),

//                 _SectionLabel('Personal Information'),
//                 _AppInput(
//                   controller: _fullNameController,
//                   label: 'Full Name',
//                   hint: 'Enter your full name',
//                   icon: Icons.person_rounded,
//                   validator: _required('Full name'),
//                 ),
//                 _AppInput(
//                   controller: _emailController,
//                   label: 'Email',
//                   hint: 'Enter email',
//                   icon: Icons.email_rounded,
//                   keyboardType: TextInputType.emailAddress,
//                   validator: _required('Email'),
//                 ),

//                 const SizedBox(height: 22),

//                 _SectionLabel('Phone Verification'),
//                 _AppInput(
//                   controller: _phoneController,
//                   label: 'Phone Number',
//                   hint: 'Example: 0591334447',
//                   icon: Icons.phone_rounded,
//                   keyboardType: TextInputType.phone,
//                   validator: _required('Phone number'),
//                 ),
//                 _AppInput(
//                   controller: _whatsappController,
//                   label: 'WhatsApp Number',
//                   hint: 'Example: 0591334447',
//                   icon: Icons.chat_rounded,
//                   keyboardType: TextInputType.phone,
//                   validator: _required('WhatsApp number'),
//                 ),
//                 _OtpSection(
//                   verified: _phoneVerified,
//                   sendingOtp: _sendingOtp,
//                   verifyingOtp: _verifyingOtp,
//                   otpController: _otpController,
//                   onSendOtp: _sendOtp,
//                   onVerifyOtp: _verifyOtp,
//                 ),

//                 const SizedBox(height: 22),

//                 _SectionLabel('Ghana Card Verification'),
//                 _AppInput(
//                   controller: _ghanaCardNumberController,
//                   label: 'Ghana Card Number',
//                   hint: 'Example: GHA-XXXXXXXXX-X',
//                   icon: Icons.badge_rounded,
//                   validator: _required('Ghana Card number'),
//                 ),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: _DocumentUploadBox(
//                         title: 'Front',
//                         imageUrl: _ghanaCardFrontUrl,
//                         onTap: _pickGhanaCardFront,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: _DocumentUploadBox(
//                         title: 'Back',
//                         imageUrl: _ghanaCardBackUrl,
//                         onTap: _pickGhanaCardBack,
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 22),

//                 _SectionLabel('Vehicle Information'),
//                 _AppInput(
//                   controller: _vehicleTypeController,
//                   label: 'Vehicle Type',
//                   hint: 'Motorbike, car, bicycle',
//                   icon: Icons.delivery_dining_rounded,
//                   validator: _required('Vehicle type'),
//                 ),
//                 _AppInput(
//                   controller: _vehicleMakeController,
//                   label: 'Vehicle Make',
//                   hint: 'Example: Honda, Yamaha, Toyota',
//                   icon: Icons.two_wheeler_rounded,
//                   validator: _required('Vehicle make'),
//                 ),
//                 _AppInput(
//                   controller: _vehicleColorController,
//                   label: 'Vehicle Color',
//                   hint: 'Example: Black',
//                   icon: Icons.color_lens_rounded,
//                   validator: _required('Vehicle color'),
//                 ),
//                 _AppInput(
//                   controller: _plateNumberController,
//                   label: 'Plate Number',
//                   hint: 'Example: GR 1234-24',
//                   icon: Icons.confirmation_number_rounded,
//                   textCapitalization: TextCapitalization.characters,
//                   validator: _required('Plate number'),
//                 ),

//                 const SizedBox(height: 22),

//                 _SectionLabel('Rider Location'),
//                 _LocationPickerTile(
//                   address: _addressController.text,
//                   subtitle: _digitalAddressController.text,
//                   onTap: _openLocationPicker,
//                 ),
//                 _AppInput(
//                   controller: _landmarkController,
//                   label: 'Landmark',
//                   hint: 'Example: Near Shell filling station',
//                   icon: Icons.place_rounded,
//                   validator: _required('Landmark'),
//                 ),

//                 const SizedBox(height: 28),

//                 SizedBox(
//                   width: double.infinity,
//                   height: 54,
//                   child: ElevatedButton(
//                     onPressed: _saving ? null : _save,
//                     style: ElevatedButton.styleFrom(
//                       elevation: 0,
//                       backgroundColor: const Color(0xFF2563EB),
//                       foregroundColor: Colors.white,
//                       disabledBackgroundColor: const Color(0xFF93B4F5),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                     ),
//                     child: Text(
//                       _saving ? 'Saving...' : 'Save changes',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w800,
//                         fontSize: 15,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   String? Function(String?) _required(String fieldName) {
//     return (value) {
//       if (value == null || value.trim().isEmpty) {
//         return '$fieldName is required';
//       }
//       return null;
//     };
//   }

//   String? _normalizeGhanaPhone(String input) {
//     final raw = input.trim().replaceAll(' ', '').replaceAll('-', '');

//     if (raw.startsWith('+233') && raw.length == 13) return raw;

//     if (raw.startsWith('233') && raw.length == 12) {
//       return '+$raw';
//     }

//     if (raw.startsWith('0') && raw.length == 10) {
//       return '+233${raw.substring(1)}';
//     }

//     return null;
//   }

//   Map<String, dynamic> _asMap(dynamic value) {
//     if (value is Map<String, dynamic>) return value;
//     if (value is Map) return Map<String, dynamic>.from(value);
//     return <String, dynamic>{};
//   }

//   String _readString(dynamic value, {String fallback = ''}) {
//     if (value == null) return fallback;
//     final text = value.toString().trim();
//     return text.isEmpty ? fallback : text;
//   }

//   bool _readBool(dynamic value, {bool fallback = false}) {
//     if (value is bool) return value;
//     return fallback;
//   }

//   double? _readDouble(dynamic value) {
//     if (value is double) return value;
//     if (value is int) return value.toDouble();
//     if (value is num) return value.toDouble();
//     return double.tryParse(value?.toString() ?? '');
//   }

//   double? _readGeoPointLat(Map<String, dynamic> location) {
//     final point = location['geopoint'];
//     if (point is GeoPoint) return point.latitude;
//     return null;
//   }

//   double? _readGeoPointLng(Map<String, dynamic> location) {
//     final point = location['geopoint'];
//     if (point is GeoPoint) return point.longitude;
//     return null;
//   }

//   void _showSnackBar(String message) {
//     if (!mounted) return;

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
//     );
//   }
// }

// class _HeaderPhoto extends StatelessWidget {
//   final String imageUrl;
//   final bool loading;
//   final String emptyText;
//   final String buttonText;
//   final VoidCallback onTap;

//   const _HeaderPhoto({
//     required this.imageUrl,
//     required this.loading,
//     required this.emptyText,
//     required this.buttonText,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final hasImage = imageUrl.trim().isNotEmpty;

//     return GestureDetector(
//       onTap: loading ? null : onTap,
//       child: Container(
//         width: double.infinity,
//         height: 190,
//         decoration: BoxDecoration(
//           color: const Color(0xFFE8EEF8),
//           borderRadius: BorderRadius.circular(22),
//           border: Border.all(color: const Color(0xFFE4E7EC)),
//         ),
//         child: Stack(
//           children: [
//             Positioned.fill(
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(22),
//                 child: loading
//                     ? const Center(
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                     : hasImage
//                     ? Image.network(
//                         imageUrl,
//                         fit: BoxFit.cover,
//                         errorBuilder: (_, __, ___) {
//                           return _EmptyProfileContent(text: emptyText);
//                         },
//                       )
//                     : _EmptyProfileContent(text: emptyText),
//               ),
//             ),
//             if (hasImage && !loading)
//               Positioned(
//                 right: 12,
//                 bottom: 12,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 14,
//                     vertical: 10,
//                   ),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFF2563EB),
//                     borderRadius: BorderRadius.circular(999),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.15),
//                         blurRadius: 12,
//                         offset: const Offset(0, 5),
//                       ),
//                     ],
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       const Icon(
//                         Icons.edit_rounded,
//                         color: Colors.white,
//                         size: 16,
//                       ),
//                       const SizedBox(width: 6),
//                       Text(
//                         buttonText,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 12,
//                           fontWeight: FontWeight.w800,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _EmptyProfileContent extends StatelessWidget {
//   final String text;

//   const _EmptyProfileContent({required this.text});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Text(
//         text,
//         textAlign: TextAlign.center,
//         style: const TextStyle(
//           color: Color(0xFF344054),
//           fontSize: 18,
//           fontWeight: FontWeight.w900,
//         ),
//       ),
//     );
//   }
// }

// class _OtpSection extends StatelessWidget {
//   final bool verified;
//   final bool sendingOtp;
//   final bool verifyingOtp;
//   final TextEditingController otpController;
//   final VoidCallback onSendOtp;
//   final VoidCallback onVerifyOtp;

//   const _OtpSection({
//     required this.verified,
//     required this.sendingOtp,
//     required this.verifyingOtp,
//     required this.otpController,
//     required this.onSendOtp,
//     required this.onVerifyOtp,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (verified) {
//       return Container(
//         width: double.infinity,
//         margin: const EdgeInsets.only(bottom: 10),
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: const Color(0xFFEAFBF1),
//           borderRadius: BorderRadius.circular(15),
//           border: Border.all(color: const Color(0xFFB7E4C7)),
//         ),
//         child: const Row(
//           children: [
//             Icon(Icons.verified_rounded, color: Color(0xFF027A48)),
//             SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 'Phone number verified',
//                 style: TextStyle(
//                   color: Color(0xFF027A48),
//                   fontWeight: FontWeight.w800,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return Column(
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: _SmallButton(
//                 label: sendingOtp ? 'Sending...' : 'Send OTP',
//                 icon: Icons.sms_rounded,
//                 onTap: sendingOtp ? null : onSendOtp,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         _AppInput(
//           controller: otpController,
//           label: 'OTP Code',
//           hint: 'Enter 6-digit OTP',
//           icon: Icons.pin_rounded,
//           keyboardType: TextInputType.number,
//         ),
//         _SmallButton(
//           label: verifyingOtp ? 'Verifying...' : 'Verify OTP',
//           icon: Icons.verified_user_rounded,
//           onTap: verifyingOtp ? null : onVerifyOtp,
//         ),
//       ],
//     );
//   }
// }

// class _DocumentUploadBox extends StatelessWidget {
//   final String title;
//   final String imageUrl;
//   final VoidCallback onTap;

//   const _DocumentUploadBox({
//     required this.title,
//     required this.imageUrl,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final hasImage = imageUrl.trim().isNotEmpty;

//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         height: 130,
//         decoration: BoxDecoration(
//           color: const Color(0xFFE8EEF8),
//           borderRadius: BorderRadius.circular(18),
//           border: Border.all(color: const Color(0xFFE4E7EC)),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(18),
//           child: hasImage
//               ? Stack(
//                   fit: StackFit.expand,
//                   children: [
//                     Image.network(imageUrl, fit: BoxFit.cover),
//                     Positioned(
//                       right: 8,
//                       bottom: 8,
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 10,
//                           vertical: 7,
//                         ),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFF2563EB),
//                           borderRadius: BorderRadius.circular(999),
//                         ),
//                         child: const Text(
//                           'Change',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 11,
//                             fontWeight: FontWeight.w800,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 )
//               : Center(
//                   child: Text(
//                     'Upload $title',
//                     style: const TextStyle(
//                       color: Color(0xFF344054),
//                       fontWeight: FontWeight.w900,
//                     ),
//                   ),
//                 ),
//         ),
//       ),
//     );
//   }
// }

// class _SmallButton extends StatelessWidget {
//   final String label;
//   final IconData icon;
//   final VoidCallback? onTap;

//   const _SmallButton({
//     required this.label,
//     required this.icon,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 48,
//       width: double.infinity,
//       child: ElevatedButton.icon(
//         onPressed: onTap,
//         icon: Icon(icon, size: 18),
//         label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
//         style: ElevatedButton.styleFrom(
//           elevation: 0,
//           backgroundColor: const Color(0xFF2563EB),
//           foregroundColor: Colors.white,
//           disabledBackgroundColor: const Color(0xFF93B4F5),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(15),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _SectionLabel extends StatelessWidget {
//   final String title;

//   const _SectionLabel(this.title);

//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: Alignment.centerLeft,
//       child: Padding(
//         padding: const EdgeInsets.only(left: 2, bottom: 10),
//         child: Text(
//           title,
//           style: const TextStyle(
//             fontSize: 13,
//             fontWeight: FontWeight.w800,
//             color: Color(0xFF344054),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _LocationPickerTile extends StatelessWidget {
//   final String address;
//   final String subtitle;
//   final VoidCallback onTap;

//   const _LocationPickerTile({
//     required this.address,
//     required this.subtitle,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final hasAddress = address.trim().isNotEmpty;

//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: double.infinity,
//         margin: const EdgeInsets.only(bottom: 10),
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(15),
//           border: Border.all(color: const Color(0xFFE4E7EC)),
//         ),
//         child: Row(
//           children: [
//             const Icon(
//               Icons.location_on_rounded,
//               color: Color(0xFF2563EB),
//               size: 22,
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     hasAddress ? address : 'Choose rider location',
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                       color: hasAddress
//                           ? const Color(0xFF101828)
//                           : const Color(0xFF98A2B3),
//                     ),
//                   ),
//                   if (subtitle.trim().isNotEmpty) ...[
//                     const SizedBox(height: 3),
//                     Text(
//                       subtitle,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         fontSize: 12,
//                         color: Color(0xFF667085),
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//             const Icon(
//               Icons.keyboard_arrow_right_rounded,
//               color: Color(0xFF98A2B3),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _AppInput extends StatelessWidget {
//   final TextEditingController controller;
//   final String label;
//   final String hint;
//   final IconData icon;
//   final TextInputType? keyboardType;
//   final int maxLines;
//   final TextCapitalization textCapitalization;
//   final String? Function(String?)? validator;

//   const _AppInput({
//     required this.controller,
//     required this.label,
//     required this.hint,
//     required this.icon,
//     this.keyboardType,
//     this.maxLines = 1,
//     this.textCapitalization = TextCapitalization.none,
//     this.validator,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: keyboardType,
//         maxLines: maxLines,
//         validator: validator,
//         textCapitalization: textCapitalization,
//         decoration: InputDecoration(
//           prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
//           labelText: label,
//           hintText: hint,
//           filled: true,
//           fillColor: Colors.white,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(15),
//             borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(15),
//             borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(15),
//             borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.3),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lundri_connect/screens/laundry/location_picker.dart';
import 'package:provider/provider.dart';

import '../../models/rider_model.dart';
import '../../providers/user_provider.dart';

class PickedLocationResult {
  final double latitude;
  final double longitude;
  final String addressLine;
  final String subtitle;
  final String serviceType;

  const PickedLocationResult({
    required this.latitude,
    required this.longitude,
    required this.addressLine,
    required this.subtitle,
    required this.serviceType,
  });
}

class RiderProfileSetupScreen extends StatefulWidget {
  const RiderProfileSetupScreen({super.key});

  @override
  State<RiderProfileSetupScreen> createState() =>
      _RiderProfileSetupScreenState();
}

class _RiderProfileSetupScreenState extends State<RiderProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _auth = fb_auth.FirebaseAuth.instance;
  final _picker = ImagePicker();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _otpController;
  late final TextEditingController _addressController;
  late final TextEditingController _digitalAddressController;
  late final TextEditingController _landmarkController;
  late final TextEditingController _ghanaCardNumberController;
  late final TextEditingController _vehicleTypeController;
  late final TextEditingController _vehicleMakeController;
  late final TextEditingController _vehicleColorController;
  late final TextEditingController _plateNumberController;

  RiderModel? loadedRider;

  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  bool _sendingOtp = false;
  bool _verifyingOtp = false;
  bool _phoneVerified = false;

  String _profilePhotoUrl = '';
  String _ghanaCardFrontUrl = '';
  String _ghanaCardBackUrl = '';
  String _verificationId = '';

  double? _selectedLatitude;
  double? _selectedLongitude;

  String get _riderId {
    final user = context.read<UserProvider>().currentUser;
    return user?.id ?? _auth.currentUser?.uid ?? '';
  }

  @override
  void initState() {
    super.initState();

    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _whatsappController = TextEditingController();
    _otpController = TextEditingController();
    _addressController = TextEditingController();
    _digitalAddressController = TextEditingController();
    _landmarkController = TextEditingController();
    _ghanaCardNumberController = TextEditingController();
    _vehicleTypeController = TextEditingController();
    _vehicleMakeController = TextEditingController();
    _vehicleColorController = TextEditingController();
    _plateNumberController = TextEditingController();

    _loadRiderData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _otpController.dispose();
    _addressController.dispose();
    _digitalAddressController.dispose();
    _landmarkController.dispose();
    _ghanaCardNumberController.dispose();
    _vehicleTypeController.dispose();
    _vehicleMakeController.dispose();
    _vehicleColorController.dispose();
    _plateNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadRiderData() async {
    if (_riderId.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    try {
      final doc = await _firestore.collection('riders').doc(_riderId).get();

      if (!doc.exists) {
        loadedRider = RiderModel.fromMap({}, _riderId);
        setState(() => _loading = false);
        return;
      }

      final rider = RiderModel.fromDocument(doc);
      final data = doc.data() ?? <String, dynamic>{};

      final verification = _asMap(data['verification']);
      final ghanaCard = _asMap(verification['ghanaCard']);
      final contact = _asMap(data['contact']);

      loadedRider = rider;

      _fullNameController.text = rider.fullName;
      _emailController.text = rider.email;
      _phoneController.text = rider.phoneNumber;
      _whatsappController.text = rider.whatsappNumber;

      _addressController.text = rider.addressLine;
      _digitalAddressController.text = rider.digitalAddress;
      _landmarkController.text = rider.landmark;

      _vehicleTypeController.text = rider.vehicleType;
      _vehicleMakeController.text = rider.vehicleMake;
      _vehicleColorController.text = rider.vehicleColor;
      _plateNumberController.text = rider.plateNumber;

      _profilePhotoUrl = rider.photoUrl;

      _selectedLatitude = rider.latitude;
      _selectedLongitude = rider.longitude;

      _phoneVerified = _readBool(contact['phoneVerified']);

      _ghanaCardNumberController.text = _readString(ghanaCard['number']);
      _ghanaCardFrontUrl = _readString(ghanaCard['frontImageUrl']);
      _ghanaCardBackUrl = _readString(ghanaCard['backImageUrl']);
    } catch (e) {
      debugPrint('Load rider data error: $e');
      _showSnackBar('Could not load rider profile');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUploadImage({
    required String storagePath,
    required void Function(String url) onUploaded,
    required String successMessage,
  }) async {
    if (_riderId.isEmpty || _uploading) return;

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (picked == null) return;

      setState(() => _uploading = true);

      final file = File(picked.path);
      final ref = _storage.ref(storagePath);

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      onUploaded(url);
      _showSnackBar(successMessage);
    } on PlatformException catch (e) {
      debugPrint('Image picker error: ${e.message}');
      _showSnackBar('Image picker failed. Restart the app.');
    } catch (e) {
      debugPrint('Image upload error: $e');
      _showSnackBar('Image upload failed');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickProfilePhoto() async {
    await _pickAndUploadImage(
      storagePath: 'riders/$_riderId/profile/profile_photo.jpg',
      successMessage: 'Profile photo added',
      onUploaded: (url) {
        setState(() => _profilePhotoUrl = url);
      },
    );
  }

  Future<void> _pickGhanaCardFront() async {
    await _pickAndUploadImage(
      storagePath: 'riders/$_riderId/verification/ghana_card_front.jpg',
      successMessage: 'Ghana Card front uploaded',
      onUploaded: (url) {
        setState(() => _ghanaCardFrontUrl = url);
      },
    );
  }

  Future<void> _pickGhanaCardBack() async {
    await _pickAndUploadImage(
      storagePath: 'riders/$_riderId/verification/ghana_card_back.jpg',
      successMessage: 'Ghana Card back uploaded',
      onUploaded: (url) {
        setState(() => _ghanaCardBackUrl = url);
      },
    );
  }

  Future<void> _sendOtp() async {
    final phone = _normalizeGhanaPhone(_phoneController.text);

    if (phone == null) {
      _showSnackBar('Enter a valid Ghana phone number');
      return;
    }

    setState(() => _sendingOtp = true);

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          try {
            final user = _auth.currentUser;
            if (user != null) {
              await user.linkWithCredential(credential).catchError((_) {});
            }

            if (!mounted) return;
            setState(() => _phoneVerified = true);
            _showSnackBar('Phone number verified');
          } catch (_) {}
        },
        verificationFailed: (e) {
          debugPrint('OTP verification failed: ${e.code}');
          _showSnackBar('Could not send OTP');
        },
        codeSent: (verificationId, resendToken) {
          setState(() => _verificationId = verificationId);
          _showSnackBar('OTP sent');
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      debugPrint('Send OTP error: $e');
      _showSnackBar('Could not send OTP');
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();

    if (_verificationId.isEmpty) {
      _showSnackBar('Request OTP first');
      return;
    }

    if (code.length < 6) {
      _showSnackBar('Enter the 6-digit OTP');
      return;
    }

    setState(() => _verifyingOtp = true);

    try {
      final credential = fb_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: code,
      );

      final user = _auth.currentUser;
      if (user != null) {
        await user.linkWithCredential(credential).catchError((_) {});
      }

      setState(() => _phoneVerified = true);
      _showSnackBar('Phone number verified');
    } catch (e) {
      debugPrint('Verify OTP error: $e');
      _showSnackBar('Invalid OTP');
    } finally {
      if (mounted) setState(() => _verifyingOtp = false);
    }
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.of(context).push<PickedLocationResult>(
      MaterialPageRoute(
        builder: (_) =>
            const GoogleMapLocationPickerScreen(serviceType: 'rider_home'),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      _addressController.text = result.addressLine;
      _digitalAddressController.text = result.subtitle;
      _selectedLatitude = result.latitude;
      _selectedLongitude = result.longitude;
    });
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _riderId.isEmpty) return;

    if (!_phoneVerified) {
      _showSnackBar('Please verify your phone number');
      return;
    }

    if (_profilePhotoUrl.trim().isEmpty) {
      _showSnackBar('Please add a profile photo');
      return;
    }

    if (_ghanaCardFrontUrl.trim().isEmpty || _ghanaCardBackUrl.trim().isEmpty) {
      _showSnackBar('Please upload both sides of your Ghana Card');
      return;
    }

    if (_selectedLatitude == null || _selectedLongitude == null) {
      _showSnackBar('Please choose your rider location');
      return;
    }

    setState(() => _saving = true);

    try {
      final docRef = _firestore.collection('riders').doc(_riderId);
      final oldSnap = await docRef.get();

      final existingRider = oldSnap.exists
          ? RiderModel.fromDocument(oldSnap)
          : RiderModel.fromMap({}, _riderId);

      final phone =
          _normalizeGhanaPhone(_phoneController.text) ??
          _phoneController.text.trim();

      final updatedRider = existingRider.copyWith(
        isProfileCompleted: true,
        fullName: _fullNameController.text.trim(),
        photoUrl: _profilePhotoUrl,
        phoneNumber: phone,
        email: _emailController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
        addressLine: _addressController.text.trim(),
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
        digitalAddress: _digitalAddressController.text.trim(),
        landmark: _landmarkController.text.trim(),
        lastLocationUpdatedAt: DateTime.now(),
        vehicleType: _vehicleTypeController.text.trim(),
        vehicleMake: _vehicleMakeController.text.trim(),
        vehicleColor: _vehicleColorController.text.trim(),
        plateNumber: _plateNumberController.text.trim().toUpperCase(),
        updatedAt: DateTime.now(),
        lastSeen: DateTime.now(),
        lastLoginAt: existingRider.lastLoginAt ?? DateTime.now(),
        createdAt: existingRider.createdAt ?? DateTime.now(),
      );

      final data = updatedRider.toMap();

      data['isProfileCompleted'] = true;

      data['contact'] = {
        ..._asMap(data['contact']),
        'phoneVerified': _phoneVerified,
        'phoneVerifiedAt': FieldValue.serverTimestamp(),
      };

      data['location'] = {
        ..._asMap(data['location']),
        'geopoint': GeoPoint(_selectedLatitude!, _selectedLongitude!),
        'geohash': null,
        'lastLocationUpdatedAt': FieldValue.serverTimestamp(),
      };

      data['verification'] = {
        'status': 'pending_review',
        'submittedAt': FieldValue.serverTimestamp(),
        'ghanaCard': {
          'number': _ghanaCardNumberController.text.trim(),
          'frontImageUrl': _ghanaCardFrontUrl,
          'backImageUrl': _ghanaCardBackUrl,
        },
      };

      data['timestamps'] = {
        ..._asMap(data['timestamps']),
        'createdAt': existingRider.createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(existingRider.createdAt!),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': existingRider.lastLoginAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(existingRider.lastLoginAt!),
        'lastSeen': FieldValue.serverTimestamp(),
      };

      await docRef.set(data, SetOptions(merge: true));

      if (!mounted) return;

      _showSnackBar('Rider profile submitted for review');
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Save rider profile error: $e');
      _showSnackBar('Could not save rider profile');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F9FC),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        foregroundColor: const Color(0xFF101828),
        title: const Text(
          'Rider Profile Setup',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _HeaderPhoto(
                  imageUrl: _profilePhotoUrl,
                  loading: _uploading,
                  emptyText: 'Add rider profile',
                  buttonText: 'Change profile',
                  onTap: _pickProfilePhoto,
                ),
                const SizedBox(height: 28),

                _SectionLabel('Personal Information'),
                _AppInput(
                  controller: _fullNameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  icon: Icons.person_rounded,
                  validator: _required('Full name'),
                ),
                _AppInput(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter email',
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: _required('Email'),
                ),

                const SizedBox(height: 22),

                _SectionLabel('Phone Verification'),
                _AppInput(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Example: 0591334447',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: _required('Phone number'),
                ),
                _AppInput(
                  controller: _whatsappController,
                  label: 'WhatsApp Number',
                  hint: 'Example: 0591334447',
                  icon: Icons.chat_rounded,
                  keyboardType: TextInputType.phone,
                  validator: _required('WhatsApp number'),
                ),
                _OtpSection(
                  verified: _phoneVerified,
                  sendingOtp: _sendingOtp,
                  verifyingOtp: _verifyingOtp,
                  otpController: _otpController,
                  onSendOtp: _sendOtp,
                  onVerifyOtp: _verifyOtp,
                ),

                const SizedBox(height: 22),

                _SectionLabel('Ghana Card Verification'),
                _AppInput(
                  controller: _ghanaCardNumberController,
                  label: 'Ghana Card Number',
                  hint: 'Example: GHA-XXXXXXXXX-X',
                  icon: Icons.badge_rounded,
                  validator: _required('Ghana Card number'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _DocumentUploadBox(
                        title: 'Front',
                        imageUrl: _ghanaCardFrontUrl,
                        onTap: _pickGhanaCardFront,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DocumentUploadBox(
                        title: 'Back',
                        imageUrl: _ghanaCardBackUrl,
                        onTap: _pickGhanaCardBack,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                _SectionLabel('Vehicle Information'),
                _AppInput(
                  controller: _vehicleTypeController,
                  label: 'Vehicle Type',
                  hint: 'Motorbike, car, bicycle',
                  icon: Icons.delivery_dining_rounded,
                  validator: _required('Vehicle type'),
                ),
                _AppInput(
                  controller: _vehicleMakeController,
                  label: 'Vehicle Make',
                  hint: 'Example: Honda, Yamaha, Toyota',
                  icon: Icons.two_wheeler_rounded,
                  validator: _required('Vehicle make'),
                ),
                _AppInput(
                  controller: _vehicleColorController,
                  label: 'Vehicle Color',
                  hint: 'Example: Black',
                  icon: Icons.color_lens_rounded,
                  validator: _required('Vehicle color'),
                ),
                _AppInput(
                  controller: _plateNumberController,
                  label: 'Plate Number',
                  hint: 'Example: GR 1234-24',
                  icon: Icons.confirmation_number_rounded,
                  textCapitalization: TextCapitalization.characters,
                  validator: _required('Plate number'),
                ),

                const SizedBox(height: 22),

                _SectionLabel('Rider Location'),
                _LocationPickerTile(
                  address: _addressController.text,
                  subtitle: _digitalAddressController.text,
                  onTap: _openLocationPicker,
                ),
                _AppInput(
                  controller: _landmarkController,
                  label: 'Landmark',
                  hint: 'Example: Near Shell filling station',
                  icon: Icons.place_rounded,
                  validator: _required('Landmark'),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF93B4F5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _saving ? 'Saving...' : 'Save changes',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? Function(String?) _required(String fieldName) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return '$fieldName is required';
      }
      return null;
    };
  }

  String? _normalizeGhanaPhone(String input) {
    final raw = input.trim().replaceAll(' ', '').replaceAll('-', '');

    if (raw.startsWith('+233') && raw.length == 13) return raw;

    if (raw.startsWith('233') && raw.length == 12) {
      return '+$raw';
    }

    if (raw.startsWith('0') && raw.length == 10) {
      return '+233${raw.substring(1)}';
    }

    return null;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  bool _readBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    return fallback;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _HeaderPhoto extends StatelessWidget {
  final String imageUrl;
  final bool loading;
  final String emptyText;
  final String buttonText;
  final VoidCallback onTap;

  const _HeaderPhoto({
    required this.imageUrl,
    required this.loading,
    required this.emptyText,
    required this.buttonText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EEF8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: loading
                    ? const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : hasImage
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return _EmptyProfileContent(text: emptyText);
                        },
                      )
                    : _EmptyProfileContent(text: emptyText),
              ),
            ),
            if (hasImage && !loading)
              Positioned(
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        buttonText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyProfileContent extends StatelessWidget {
  final String text;

  const _EmptyProfileContent({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF344054),
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _OtpSection extends StatelessWidget {
  final bool verified;
  final bool sendingOtp;
  final bool verifyingOtp;
  final TextEditingController otpController;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;

  const _OtpSection({
    required this.verified,
    required this.sendingOtp,
    required this.verifyingOtp,
    required this.otpController,
    required this.onSendOtp,
    required this.onVerifyOtp,
  });

  @override
  Widget build(BuildContext context) {
    if (verified) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEAFBF1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFB7E4C7)),
        ),
        child: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF027A48)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Phone number verified',
                style: TextStyle(
                  color: Color(0xFF027A48),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SmallButton(
                label: sendingOtp ? 'Sending...' : 'Send OTP',
                icon: Icons.sms_rounded,
                onTap: sendingOtp ? null : onSendOtp,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _AppInput(
          controller: otpController,
          label: 'OTP Code',
          hint: 'Enter 6-digit OTP',
          icon: Icons.pin_rounded,
          keyboardType: TextInputType.number,
        ),
        _SmallButton(
          label: verifyingOtp ? 'Verifying...' : 'Verify OTP',
          icon: Icons.verified_user_rounded,
          onTap: verifyingOtp ? null : onVerifyOtp,
        ),
      ],
    );
  }
}

class _DocumentUploadBox extends StatelessWidget {
  final String title;
  final String imageUrl;
  final VoidCallback onTap;

  const _DocumentUploadBox({
    required this.title,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          color: const Color(0xFFE8EEF8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(imageUrl, fit: BoxFit.cover),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Change',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Text(
                    'Upload $title',
                    style: const TextStyle(
                      color: Color(0xFF344054),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _SmallButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF93B4F5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF344054),
          ),
        ),
      ),
    );
  }
}

class _LocationPickerTile extends StatelessWidget {
  final String address;
  final String subtitle;
  final VoidCallback onTap;

  const _LocationPickerTile({
    required this.address,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAddress = address.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE4E7EC)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF2563EB),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasAddress ? address : 'Choose rider location',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: hasAddress
                          ? const Color(0xFF101828)
                          : const Color(0xFF98A2B3),
                    ),
                  ),
                  if (subtitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_right_rounded,
              color: Color(0xFF98A2B3),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  const _AppInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFFE4E7EC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.3),
          ),
        ),
      ),
    );
  }
}
