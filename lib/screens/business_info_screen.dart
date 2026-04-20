import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/helpers.dart';
import '../core/utils/validators.dart';
import '../models/business_info_model.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class BusinessInfoScreen extends StatefulWidget {
  const BusinessInfoScreen({super.key});

  @override
  State<BusinessInfoScreen> createState() => _BusinessInfoScreenState();
}

class _BusinessInfoScreenState extends State<BusinessInfoScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _businessNameController;
  late final TextEditingController _ownerNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _descriptionController;

  bool _pickupAvailable = true;
  bool _deliveryAvailable = true;

  @override
  void initState() {
    super.initState();
    final info = context.read<UserProvider>().businessInfo;

    _businessNameController = TextEditingController(
      text: info?.businessName ?? '',
    );
    _ownerNameController = TextEditingController(text: info?.ownerName ?? '');
    _phoneController = TextEditingController(text: info?.phoneNumber ?? '');
    _emailController = TextEditingController(text: info?.email ?? '');
    _addressController = TextEditingController(text: info?.address ?? '');
    _descriptionController = TextEditingController(
      text: info?.description ?? '',
    );

    _pickupAvailable = info?.pickupAvailable ?? true;
    _deliveryAvailable = info?.deliveryAvailable ?? true;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final businessInfo = BusinessInfoModel(
      businessName: _businessNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      description: _descriptionController.text.trim(),
      pickupAvailable: _pickupAvailable,
      deliveryAvailable: _deliveryAvailable,
    );

    context.read<UserProvider>().updateBusinessInfo(businessInfo);

    Helpers.showSnackBar(context, 'Business info updated');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Info')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                  controller: _businessNameController,
                  hintText: 'Enter business name',
                  labelText: 'Business Name',
                  validator: (value) => Validators.validateRequired(
                    value,
                    fieldName: 'Business name',
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _ownerNameController,
                  hintText: 'Enter owner name',
                  labelText: 'Owner Name',
                  validator: (value) => Validators.validateRequired(
                    value,
                    fieldName: 'Owner name',
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  hintText: 'Enter phone number',
                  labelText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  validator: Validators.validatePhone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  hintText: 'Enter email',
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _addressController,
                  hintText: 'Enter business address',
                  labelText: 'Address',
                  validator: (value) =>
                      Validators.validateRequired(value, fieldName: 'Address'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _descriptionController,
                  hintText: 'Write a short description',
                  labelText: 'Description',
                  maxLines: 4,
                  validator: (value) => Validators.validateRequired(
                    value,
                    fieldName: 'Description',
                  ),
                ),
                const SizedBox(height: 18),
                SwitchListTile(
                  value: _pickupAvailable,
                  onChanged: (value) {
                    setState(() {
                      _pickupAvailable = value;
                    });
                  },
                  title: const Text('Pickup Available'),
                ),
                SwitchListTile(
                  value: _deliveryAvailable,
                  onChanged: (value) {
                    setState(() {
                      _deliveryAvailable = value;
                    });
                  },
                  title: const Text('Delivery Available'),
                ),
                const SizedBox(height: 20),
                CustomButton(text: 'Save Changes', onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
