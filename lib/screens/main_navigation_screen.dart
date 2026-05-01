import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lundri_connect/screens/laundry/operator_home_screen.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'laundry/laundry_profile_screen.dart';
import 'laundry/requests_screen.dart';
import 'rider/active_orders_screen.dart';
import 'rider/rider_home_screen.dart';
import 'rider/rider_profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NavigationProvider>().setIndex(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().selectedRole;
    final navigationProvider = context.watch<NavigationProvider>();
    final user = context.watch<UserProvider>().currentUser;

    final isRider = role == 'rider';
    final collectionName = isRider ? 'riders' : 'laundries';
    final uid = user?.id ?? '';

    final items = isRider ? _riderItems : _operatorItems;

    final safeIndex = navigationProvider.currentIndex >= items.length
        ? 0
        : navigationProvider.currentIndex;

    if (uid.isEmpty) {
      return Scaffold(
        body: IndexedStack(
          index: safeIndex,
          children: _buildScreens(isRider: isRider, isProfileCompleted: false),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: safeIndex,
          onTap: navigationProvider.setIndex,
          items: items,
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(collectionName)
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final isProfileCompleted = data['isProfileCompleted'] == true;

        final screens = _buildScreens(
          isRider: isRider,
          isProfileCompleted: isProfileCompleted,
        );

        return Scaffold(
          body: IndexedStack(index: safeIndex, children: screens),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: safeIndex,
            onTap: navigationProvider.setIndex,
            items: items,
          ),
        );
      },
    );
  }

  List<Widget> _buildScreens({
    required bool isRider,
    required bool isProfileCompleted,
  }) {
    if (isRider) {
      return [
        // RiderHomeScreen(isProfileCompleted: isProfileCompleted),
        RiderHomeScreen(),
        const ActiveOrdersScreen(),
        const RiderProfileScreen(),
      ];
    }

    return [
      OperatorHomeScreen(),
      const OrdersScreen(),
      const LaundryProfileScreen(),
    ];
  }

  static const List<BottomNavigationBarItem> _riderItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.local_shipping_outlined),
      activeIcon: Icon(Icons.local_shipping_rounded),
      label: 'Tasks',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline_rounded),
      activeIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];

  static const List<BottomNavigationBarItem> _operatorItems = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.inbox_outlined),
      activeIcon: Icon(Icons.inbox_rounded),
      label: 'Requests',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline_rounded),
      activeIcon: Icon(Icons.person_rounded),
      label: 'Profile',
    ),
  ];
}
