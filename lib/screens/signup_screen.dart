import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/routes/route_names.dart';
import '../core/utils/helpers.dart';
import '../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/payments_provider.dart';
import '../providers/rider_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'laundry';

  bool get _isOperator => _selectedRole == 'laundry';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePrimaryNameField(String? value) {
    if (_isOperator) {
      return Validators.validateLaundryServiceName(value);
    }
    return Validators.validateFullName(value);
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Please confirm your password';
    }

    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }

    return null;
  }

  Future<void> _handleSignup() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.signup(
      fullName: _isOperator ? '' : _nameController.text.trim(),
      email: _emailController.text.trim(),
      laundryServiceName: _isOperator ? _nameController.text.trim() : '',
      password: _passwordController.text.trim(),
      role: _selectedRole,
    );

    if (!mounted) return;

    if (!success) {
      Helpers.showSnackBar(
        context,
        authProvider.errorMessage.isNotEmpty
            ? authProvider.errorMessage
            : 'Signup failed. Please try again.',
      );
      return;
    }

    await context.read<OrdersProvider>().loadDemoData();
    await context.read<PaymentsProvider>().loadDemoPayments();
    await context.read<RiderProvider>().loadDemoRiderRequests();
    context.read<NavigationProvider>().reset();

    if (!mounted) return;

    Helpers.showSnackBar(context, 'Account created successfully');
    Navigator.pushReplacementNamed(context, RouteNames.mainNavigation);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create account',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create an operator or rider account for Lundri Connect.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),

                CustomTextField(
                  controller: _nameController,
                  hintText: _isOperator
                      ? 'Enter laundry service name'
                      : 'Enter full name',
                  labelText: _isOperator ? 'Laundry Service Name' : 'Full Name',
                  keyboardType: TextInputType.text,
                  prefixIcon: Icon(
                    _isOperator
                        ? Icons.local_laundry_service_outlined
                        : Icons.badge_outlined,
                  ),
                  validator: _validatePrimaryNameField,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _emailController,
                  hintText: 'Enter email address',
                  labelText: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined),
                  validator: Validators.validateEmail,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _passwordController,
                  hintText: 'Create password',
                  labelText: 'Password',
                  obscureText: _obscurePassword,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  validator: Validators.validatePassword,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm password',
                  labelText: 'Confirm Password',
                  obscureText: _obscureConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                  validator: _validateConfirmPassword,
                  textInputAction: TextInputAction.done,
                ),

                const SizedBox(height: 22),
                const Text(
                  'Select Role',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _RoleOptionCard(
                        title: 'Laundry Operator',
                        subtitle: 'Manage requests and washing',
                        icon: Icons.storefront_outlined,
                        isSelected: _selectedRole == 'laundry',
                        onTap: () {
                          setState(() {
                            _selectedRole = 'laundry';
                            _nameController.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleOptionCard(
                        title: 'Rider',
                        subtitle: 'Handle pickups and deliveries',
                        icon: Icons.delivery_dining_outlined,
                        isSelected: _selectedRole == 'rider',
                        onTap: () {
                          setState(() {
                            _selectedRole = 'rider';
                            _nameController.clear();
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                CustomButton(
                  text: 'Create Account',
                  onPressed: authProvider.isLoading ? null : _handleSignup,
                  isLoading: authProvider.isLoading,
                ),

                const SizedBox(height: 22),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.softPink : AppColors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.iconMuted,
                size: 28,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
