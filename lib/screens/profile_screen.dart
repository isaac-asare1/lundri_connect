import 'package:flutter/material.dart';
import 'package:lundri_connect/core/utils/helpers.dart';
import 'package:lundri_connect/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_colors.dart';
import '../core/routes/route_names.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/profile_menu_tile.dart';
import 'payments_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = userProvider.currentUser;
    final businessInfo = userProvider.businessInfo;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.white.withValues(alpha: 0.18),
                  child: Text(
                    _initials(user?.fullName ?? 'Lundri User'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? 'Lundri User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        businessInfo?.businessName ?? user?.email ?? '',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authProvider.selectedRole == 'rider'
                            ? 'Rider Account'
                            : 'Laundry Operator',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ProfileMenuTile(
            icon: Icons.store_outlined,
            title: 'Business Info',
            subtitle: 'Name, location, details',
            onTap: () {
              Navigator.pushNamed(context, RouteNames.businessInfo);
            },
          ),
          const SizedBox(height: 12),
          ProfileMenuTile(
            icon: Icons.access_time_outlined,
            title: 'Working Hours',
            subtitle: 'Schedule and availability',
            onTap: () {
              Navigator.pushNamed(context, RouteNames.workingHours);
            },
          ),
          const SizedBox(height: 12),
          ProfileMenuTile(
            icon: Icons.payment,
            title: 'Payments',
            subtitle: 'Track payments',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentsScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          ProfileMenuTile(
            icon: Icons.local_offer_outlined,
            title: 'Service Pricing',
            subtitle: 'Prices and laundry services',
            onTap: () {
              Navigator.pushNamed(context, RouteNames.servicePricing);
            },
          ),
          const SizedBox(height: 12),
          ProfileMenuTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Notifications and preferences',
            onTap: () {
              Navigator.pushNamed(context, RouteNames.settings);
            },
          ),
          const SizedBox(height: 12),
          ProfileMenuTile(
            icon: Icons.support_agent_outlined,
            title: 'Support',
            subtitle: 'Help center and contact',
            onTap: () {
              Navigator.pushNamed(context, RouteNames.support);
            },
          ),
          const SizedBox(height: 12),
          ProfileMenuTile(
            isLoading:
                context.watch<UserProvider>().isUpdatingOnlineStatus ||
                context.watch<AuthProvider>().isLoading,
            icon: Icons.logout_rounded,
            title: 'Log Out',
            subtitle: 'Sign out of your account',
            iconColor: AppColors.error,
            onTap: () async {
              final userProvider = context.read<UserProvider>();
              final authProvider = context.read<AuthProvider>();

              try {
                await userProvider.goOfflineBeforeLogout(
                  role: authProvider.selectedRole,
                );

                await authProvider.logout();
                userProvider.clearUser();

                if (!context.mounted) return;

                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RouteNames.login,
                  (route) => false,
                );
              } catch (_) {
                if (!context.mounted) return;

                Helpers.showSnackBar(
                  context,
                  'Unable to log out. Please try again.',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || value.trim().isEmpty) return 'LU';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
