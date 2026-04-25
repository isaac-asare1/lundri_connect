import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/utils/helpers.dart';
import '../../core/utils/validators.dart';
import '../../providers/user_provider.dart';

// Adjust these imports to match your actual file locations.
import 'location_picker.dart';

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

class LaundryBusinessInfoScreen extends StatefulWidget {
  const LaundryBusinessInfoScreen({super.key});

  @override
  State<LaundryBusinessInfoScreen> createState() =>
      _LaundryBusinessInfoScreenState();
}

class _LaundryBusinessInfoScreenState extends State<LaundryBusinessInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  static const String _googleApiKey = 'AIzaSyABK1eJNZmo0VNvGabx4JZDTQvPppSpnA0';

  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;
  final _picker = ImagePicker();

  late final TextEditingController _businessNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _ownerNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _basePriceController;
  late final TextEditingController _washIronExtraController;
  late final TextEditingController _turnaroundController;
  late final TextEditingController _locationSearchController;

  final FocusNode _locationFocusNode = FocusNode();

  bool _loading = true;
  bool _saving = false;
  bool _isSearchingLocations = false;

  bool _washFold = true;
  bool _washIron = true;

  String _photoUrl = '';
  String _selectedLocationSubtitle = '';

  double? _selectedLatitude;
  double? _selectedLongitude;

  List<PlaceSuggestion> _predictions = [];

  @override
  void initState() {
    super.initState();

    _businessNameController = TextEditingController();
    _descriptionController = TextEditingController();
    _ownerNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
    _basePriceController = TextEditingController();
    _washIronExtraController = TextEditingController();
    _turnaroundController = TextEditingController();
    _locationSearchController = TextEditingController();

    _loadLaundryData();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _basePriceController.dispose();
    _washIronExtraController.dispose();
    _turnaroundController.dispose();
    _locationSearchController.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  String get _laundryId {
    final user = context.read<UserProvider>().currentUser;
    return user?.id ?? '';
  }

  Future<void> _loadLaundryData() async {
    if (_laundryId.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    final doc = await _firestore.collection('laundries').doc(_laundryId).get();
    final data = doc.data() ?? {};

    final profile = _asMap(data['profile']);
    final owner = _asMap(data['owner']);
    final contact = _asMap(data['contact']);
    final location = _asMap(data['location']);
    final business = _asMap(data['business']);
    final pricing = _asMap(data['pricing']);
    final services = _asMap(data['services']);

    _businessNameController.text = _readString(profile['name']);
    _descriptionController.text = _readString(profile['description']);
    _ownerNameController.text = _readString(owner['fullName']);
    _emailController.text = _readString(contact['email']);
    _phoneController.text = _readString(contact['phoneNumber']);
    _addressController.text = _readString(location['addressLine']);
    _basePriceController.text = '${pricing['basePricePerKg'] ?? 18}';
    _washIronExtraController.text = '${pricing['washIronExtraPerKg'] ?? 2}';
    _turnaroundController.text = _readString(
      business['estimatedTurnaroundText'],
      fallback: 'Same day',
    );

    _washFold = _readBool(services['washFold'], fallback: true);
    _washIron = _readBool(services['washIron'], fallback: true);

    _photoUrl = _readString(profile['photoUrl']);
    _selectedLocationSubtitle = _readString(location['subtitle']);

    _selectedLatitude =
        _readDouble(location['latitude']) ?? _readDouble(data['latitude']);
    _selectedLongitude =
        _readDouble(location['longitude']) ?? _readDouble(data['longitude']);

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_laundryId.isEmpty || _saving) return;

    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 900,
      );

      if (picked == null) return;

      setState(() => _saving = true);

      final file = File(picked.path);
      final ref = _storage.ref(
        'laundries/$_laundryId/profile/profile_photo.jpg',
      );

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await _firestore.collection('laundries').doc(_laundryId).set({
        'profile': {'photoUrl': url},
        'timestamps': {'updatedAt': FieldValue.serverTimestamp()},
      }, SetOptions(merge: true));

      if (!mounted) return;

      setState(() => _photoUrl = url);
      Helpers.showSnackBar(context, 'Laundry photo updated');
    } on PlatformException catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(context, 'Image picker failed. Restart the app.');
      debugPrint('Image picker platform error: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      Helpers.showSnackBar(context, 'Image upload failed');
      debugPrint('Image upload error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showLocationSheet() async {
    _locationSearchController.clear();
    _predictions = [];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.18),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> searchPlaces(String input) async {
              final query = input.trim();

              if (query.isEmpty) {
                setModalState(() {
                  _predictions = [];
                  _isSearchingLocations = false;
                });
                return;
              }

              setModalState(() => _isSearchingLocations = true);

              try {
                final uri = Uri.parse(
                  'https://maps.googleapis.com/maps/api/place/autocomplete/json'
                  '?input=${Uri.encodeQueryComponent(query)}'
                  '&key=$_googleApiKey'
                  '&components=country:gh',
                );

                final response = await http.get(uri);
                final data = jsonDecode(response.body) as Map<String, dynamic>;

                final status = (data['status'] ?? '').toString();
                final errorMessage = (data['error_message'] ?? '').toString();

                if (response.statusCode != 200) {
                  throw Exception('HTTP ${response.statusCode}');
                }

                if (status != 'OK' && status != 'ZERO_RESULTS') {
                  throw Exception(
                    errorMessage.isNotEmpty ? '$status: $errorMessage' : status,
                  );
                }

                final results = (data['predictions'] as List<dynamic>? ?? [])
                    .map(
                      (e) =>
                          PlaceSuggestion.fromJson(e as Map<String, dynamic>),
                    )
                    .toList();

                if (!mounted) return;

                setModalState(() {
                  _predictions = results;
                  _isSearchingLocations = false;
                });
              } catch (e) {
                debugPrint('Places autocomplete failed: $e');

                if (!mounted) return;

                setModalState(() {
                  _predictions = [];
                  _isSearchingLocations = false;
                });

                Helpers.showSnackBar(context, 'Could not fetch locations');
              }
            }

            Future<void> selectSuggestion(PlaceSuggestion place) async {
              try {
                final uri = Uri.parse(
                  'https://maps.googleapis.com/maps/api/place/details/json'
                  '?place_id=${Uri.encodeQueryComponent(place.placeId)}'
                  '&fields=formatted_address,geometry,name'
                  '&key=$_googleApiKey',
                );

                final response = await http.get(uri);
                final data = jsonDecode(response.body) as Map<String, dynamic>;

                final status = (data['status'] ?? '').toString();

                if (response.statusCode != 200 || status != 'OK') {
                  throw Exception('Could not resolve selected location.');
                }

                final result = data['result'] as Map<String, dynamic>? ?? {};
                final geometry =
                    result['geometry'] as Map<String, dynamic>? ?? {};
                final location =
                    geometry['location'] as Map<String, dynamic>? ?? {};

                final lat = (location['lat'] as num?)?.toDouble();
                final lng = (location['lng'] as num?)?.toDouble();
                final address =
                    (result['formatted_address'] ?? place.description)
                        .toString();

                if (lat == null || lng == null) {
                  throw Exception('Invalid coordinates.');
                }

                setState(() {
                  _addressController.text = address;
                  _selectedLatitude = lat;
                  _selectedLongitude = lng;
                  _selectedLocationSubtitle = place.secondaryText;
                  _locationSearchController.clear();
                  _predictions = [];
                });

                _locationFocusNode.unfocus();

                if (Navigator.of(sheetContext).canPop()) {
                  Navigator.of(sheetContext).pop();
                }
              } catch (e) {
                debugPrint('Place details failed: $e');

                if (!mounted) return;
                Helpers.showSnackBar(context, 'Could not select location');
              }
            }

            Future<void> openMapPicker() async {
              if (Navigator.of(sheetContext).canPop()) {
                Navigator.of(sheetContext).pop();
              }

              final result = await Navigator.of(context)
                  .push<PickedLocationResult>(
                    MaterialPageRoute(
                      builder: (_) => const GoogleMapLocationPickerScreen(
                        serviceType: 'laundry_business',
                      ),
                    ),
                  );

              if (!mounted || result == null) return;

              setState(() {
                _addressController.text = result.addressLine;
                _selectedLatitude = result.latitude;
                _selectedLongitude = result.longitude;
                _selectedLocationSubtitle = result.subtitle;
                _locationSearchController.clear();
                _predictions = [];
              });
            }

            return SafeArea(
              top: false,
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.88,
                minChildSize: 0.65,
                maxChildSize: 0.92,
                builder: (context, scrollController) {
                  return Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: ListView(
                      controller: scrollController,
                      children: [
                        Center(
                          child: Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4E7EC),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Choose laundry location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _locationSearchController,
                                focusNode: _locationFocusNode,
                                onChanged: searchPlaces,
                                decoration: InputDecoration(
                                  hintText: 'Search business location',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  suffixIcon: _isSearchingLocations
                                      ? const Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: const Color(0xFFF7F9FC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: openMapPicker,
                              child: Container(
                                height: 52,
                                width: 52,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.map_rounded,
                                  color: Color(0xFFE67E22),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_predictions.isNotEmpty)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE4E7EC),
                              ),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _predictions.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final place = _predictions[index];

                                return ListTile(
                                  leading: const Icon(
                                    Icons.location_on_outlined,
                                    color: Color(0xFFE67E22),
                                  ),
                                  title: Text(
                                    place.mainText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    place.secondaryText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => selectSuggestion(place),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _laundryId.isEmpty) return;

    if (_addressController.text.trim().isEmpty ||
        _selectedLatitude == null ||
        _selectedLongitude == null) {
      Helpers.showSnackBar(context, 'Please choose a valid laundry location');
      return;
    }

    setState(() => _saving = true);

    try {
      final docRef = _firestore.collection('laundries').doc(_laundryId);
      final snapshot = await docRef.get();
      final oldData = snapshot.data() ?? {};

      final oldProfile = _asMap(oldData['profile']);
      final oldOwner = _asMap(oldData['owner']);
      final oldContact = _asMap(oldData['contact']);
      final oldLocation = _asMap(oldData['location']);
      final oldBusiness = _asMap(oldData['business']);
      final oldPricing = _asMap(oldData['pricing']);
      final oldTimestamps = _asMap(oldData['timestamps']);

      final name = _businessNameController.text.trim();
      final address = _addressController.text.trim();

      await docRef.set({
        'id': _laundryId,
        'role': 'laundry',

        // Root-level query/location fields
        'latitude': _selectedLatitude,
        'longitude': _selectedLongitude,

        'profile': {
          ...oldProfile,
          'name': name,
          'description': _descriptionController.text.trim(),
          'photoUrl': _photoUrl,
        },

        'owner': {...oldOwner, 'fullName': _ownerNameController.text.trim()},

        'contact': {
          ...oldContact,
          'email': _emailController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
        },

        'location': {
          ...oldLocation,
          'addressLine': address,
          'subtitle': _selectedLocationSubtitle,
          'latitude': _selectedLatitude,
          'longitude': _selectedLongitude,
          'lastUpdatedAt': FieldValue.serverTimestamp(),
        },

        'business': {
          ...oldBusiness,
          'estimatedTurnaroundText': _turnaroundController.text.trim(),
        },

        'services': {'washFold': _washFold, 'washIron': _washIron},

        'pricing': {
          ...oldPricing,
          'currency': 'GHS',
          'basePricePerKg': _toInt(_basePriceController.text, 18),
          'washIronExtraPerKg': _toInt(_washIronExtraController.text, 2),
          'pricingVersion': oldPricing['pricingVersion'] ?? 1,
        },

        'searchKeywords': _buildSearchKeywords(
          name: name,
          address: address,
          subtitle: _selectedLocationSubtitle,
        ),

        'timestamps': {
          'createdAt':
              oldTimestamps['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      if (!mounted) return;

      Helpers.showSnackBar(context, 'Business info updated');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      Helpers.showSnackBar(context, 'Could not update business info');
      debugPrint('Business info update error: $e');
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
          'Business Settings',
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
                  imageUrl: _photoUrl,
                  loading: _saving,
                  onTap: _pickAndUploadPhoto,
                ),
                const SizedBox(height: 28),

                _SectionLabel('Business Profile'),
                _AppInput(
                  controller: _businessNameController,
                  label: 'Laundry Name',
                  hint: 'Enter laundry name',
                  icon: Icons.storefront_rounded,
                  validator: (value) => Validators.validateRequired(
                    value,
                    fieldName: 'Laundry name',
                  ),
                ),
                _AppInput(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Write a short description',
                  icon: Icons.notes_rounded,
                  maxLines: 3,
                  validator: (value) => Validators.validateRequired(
                    value,
                    fieldName: 'Description',
                  ),
                ),
                _AppInput(
                  controller: _turnaroundController,
                  label: 'Estimated Turnaround',
                  hint: 'Example: Same day',
                  icon: Icons.schedule_rounded,
                  validator: (value) => Validators.validateRequired(
                    value,
                    fieldName: 'Estimated turnaround',
                  ),
                ),

                const SizedBox(height: 22),
                _SectionLabel('Owner & Contact'),
                _AppInput(
                  controller: _ownerNameController,
                  label: 'Owner Name',
                  hint: 'Enter owner name',
                  icon: Icons.person_rounded,
                  validator: (value) => Validators.validateRequired(
                    value,
                    fieldName: 'Owner name',
                  ),
                ),
                _AppInput(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'Enter business phone number',
                  icon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                ),
                _AppInput(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Enter email',
                  icon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),

                const SizedBox(height: 22),
                _SectionLabel('Location'),
                _LocationPickerTile(
                  address: _addressController.text,
                  subtitle: _selectedLocationSubtitle,
                  onTap: _showLocationSheet,
                ),

                const SizedBox(height: 22),
                _SectionLabel('Services'),
                _AppSwitchTile(
                  title: 'Wash & Fold',
                  subtitle: 'Allow customers to book wash and fold.',
                  icon: Icons.local_laundry_service_rounded,
                  value: _washFold,
                  onChanged: (value) => setState(() => _washFold = value),
                ),
                _AppSwitchTile(
                  title: 'Wash & Iron',
                  subtitle: 'Allow customers to add ironing.',
                  icon: Icons.iron_rounded,
                  value: _washIron,
                  onChanged: (value) => setState(() => _washIron = value),
                ),

                const SizedBox(height: 22),
                _SectionLabel('Pricing'),
                _AppInput(
                  controller: _basePriceController,
                  label: 'Base Price Per Kg',
                  hint: 'Example: 18',
                  icon: Icons.payments_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) => Validators.validateRequired(
                    value,
                    fieldName: 'Base price',
                  ),
                ),
                _AppInput(
                  controller: _washIronExtraController,
                  label: 'Wash & Iron Extra Per Kg',
                  hint: 'Example: 2',
                  icon: Icons.add_card_rounded,
                  keyboardType: TextInputType.number,
                  validator: (value) => Validators.validateRequired(
                    value,
                    fieldName: 'Wash iron extra',
                  ),
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
                      _saving ? 'Saving...' : 'Save Changes',
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

  double? _readDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  int _toInt(String value, int fallback) {
    return int.tryParse(value.trim()) ?? fallback;
  }

  List<String> _buildSearchKeywords({
    required String name,
    required String address,
    required String subtitle,
  }) {
    final words = <String>{
      'laundry',
      'wash',
      'wash fold',
      'wash iron',
      name.toLowerCase(),
      address.toLowerCase(),
      subtitle.toLowerCase(),
      ...name.toLowerCase().split(' '),
      ...address.toLowerCase().split(' '),
      ...subtitle.toLowerCase().split(' '),
    };

    words.removeWhere((word) => word.trim().isEmpty);
    return words.toList();
  }
}

class _HeaderPhoto extends StatelessWidget {
  final String imageUrl;
  final bool loading;
  final VoidCallback onTap;

  const _HeaderPhoto({
    required this.imageUrl,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl.trim().isNotEmpty;

    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFE8EEF8),
            backgroundImage: hasImage ? NetworkImage(imageUrl) : null,
            child: loading
                ? const CircularProgressIndicator(strokeWidth: 2)
                : hasImage
                ? null
                : const Icon(
                    Icons.local_laundry_service_rounded,
                    size: 38,
                    color: Color(0xFF2563EB),
                  ),
          ),
          Positioned(
            right: -2,
            bottom: 2,
            child: Container(
              height: 31,
              width: 31,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
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
                    hasAddress ? address : 'Choose business location',
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
            const SizedBox(width: 8),
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
  final String? Function(String?)? validator;

  const _AppInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
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

class _AppSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AppSwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF2563EB),
        contentPadding: const EdgeInsets.fromLTRB(14, 4, 10, 4),
        secondary: Icon(icon, size: 22, color: const Color(0xFF2563EB)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF101828),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
        ),
      ),
    );
  }
}

class PlaceSuggestion {
  final String description;
  final String mainText;
  final String secondaryText;
  final String placeId;

  const PlaceSuggestion({
    required this.description,
    required this.mainText,
    required this.secondaryText,
    required this.placeId,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    final formatting =
        json['structured_formatting'] as Map<String, dynamic>? ?? {};

    return PlaceSuggestion(
      description: (json['description'] ?? '').toString(),
      mainText: (formatting['main_text'] ?? '').toString(),
      secondaryText: (formatting['secondary_text'] ?? '').toString(),
      placeId: (json['place_id'] ?? '').toString(),
    );
  }
}
