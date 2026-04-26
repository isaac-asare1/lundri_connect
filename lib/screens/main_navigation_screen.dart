import 'package:flutter/material.dart';
import 'package:lundri_connect/screens/laundry/operator_home_screen.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'laundry/laundry_profile_screen.dart';
import 'laundry/requests_screen.dart';
import 'rider/rider_profile_screen.dart';
import 'rider/active_orders_screen.dart';
import 'rider/rider_home_screen.dart';

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

    final bool isRider = role == 'rider';

    final List<Widget> operatorScreens = const [
      OperatorHomeScreen(),
      OrdersScreen(),
      LaundryProfileScreen(),
    ];

    final List<Widget> riderScreens = const [
      RiderHomeScreen(),
      ActiveOrdersScreen(),
      RiderProfileScreen(),
    ];

    final List<Widget> screens = isRider ? riderScreens : operatorScreens;

    final List<BottomNavigationBarItem> items = isRider
        ? const [
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
          ]
        : const [
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

    final int safeIndex = navigationProvider.currentIndex >= items.length
        ? 0
        : navigationProvider.currentIndex;

    return Scaffold(
      body: IndexedStack(index: safeIndex, children: screens),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: safeIndex,
        onTap: navigationProvider.setIndex,
        items: items,
      ),
    );
  }
}
