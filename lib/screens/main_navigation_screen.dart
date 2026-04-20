import 'package:flutter/material.dart';
import 'package:lundri_connect/screens/laundry/operator_home_screen.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'active_orders_screen.dart';
import 'payments_screen.dart';
import 'profile_screen.dart';
import 'laundry/requests_screen.dart';
import 'rider_home_screen.dart';

class MainNavigationScreen extends StatelessWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().selectedRole;
    final navigationProvider = context.watch<NavigationProvider>();

    final isRider = role == 'rider';

    final operatorScreens = const [
      OperatorHomeScreen(),
      OrdersScreen(),
      ProfileScreen(),
    ];

    final riderScreens = const [
      RiderHomeScreen(),
      ActiveOrdersScreen(),
      PaymentsScreen(),
      ProfileScreen(),
    ];

    final screens = isRider ? riderScreens : operatorScreens;

    final items = isRider
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
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Payments',
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

    return Scaffold(
      body: IndexedStack(
        index: navigationProvider.currentIndex,
        children: screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: navigationProvider.currentIndex,
        onTap: navigationProvider.setIndex,
        items: items,
      ),
    );
  }
}
