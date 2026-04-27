import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lundri_connect/core/utils/helpers.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/profile_menu_tile.dart';
import '../others/payments_screen.dart';

class LaundryProfileScreen extends StatelessWidget {
  const LaundryProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = userProvider.currentUser;

    final laundryId = user?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          if (laundryId.isEmpty)
            _TopProfileCard(
              laundryName: 'Lundri User',
              ownerName: user?.email ?? '',
              photoUrl: '',
            )
          else
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('laundries')
                  .doc(laundryId)
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() ?? {};

                final profile = _asMap(data['profile']);
                final owner = _asMap(data['owner']);
                final contact = _asMap(data['contact']);

                final laundryName = _readString(
                  profile['name'],
                  fallback: user?.fullName ?? 'Lundri User',
                );

                final ownerName = _readString(
                  owner['fullName'],
                  fallback: _readString(
                    contact['email'],
                    fallback: user?.email ?? '',
                  ),
                );

                final photoUrl = _readString(profile['photoUrl']);

                return _TopProfileCard(
                  laundryName: laundryName,
                  ownerName: ownerName,
                  photoUrl: photoUrl,
                  isLoading:
                      snapshot.connectionState == ConnectionState.waiting,
                );
              },
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
                userProvider.isUpdatingOnlineStatus || authProvider.isLoading,
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

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}

class _TopProfileCard extends StatelessWidget {
  final String laundryName;
  final String ownerName;
  final String photoUrl;
  final bool isLoading;

  const _TopProfileCard({
    required this.laundryName,
    required this.ownerName,
    required this.photoUrl,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl.trim().isNotEmpty;

    return Container(
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
            backgroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
            child: hasPhoto
                ? null
                : Text(
                    _initials(laundryName),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: isLoading
                ? const Text(
                    'Loading profile...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        laundryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ownerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
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
