import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lundri_connect/core/routes/route_names.dart';
import 'package:lundri_connect/core/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../screens/rider/active_orders_screen.dart';
import 'screens/laundry/laundry_business_info_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/main_navigation_screen.dart';
import '../../screens/laundry/operator_home_screen.dart';
import '../../screens/payments_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/laundry/requests_screen.dart';
import '../../screens/rider/rider_home_screen.dart';
import '../../screens/service_pricing_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/signup_screen.dart';
import '../../screens/splash_screen.dart';
import '../../screens/support_screen.dart';
import '../../screens/working_hours_screen.dart';

import 'providers/auth_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/payments_provider.dart';
import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) rethrow;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        ChangeNotifierProvider<PaymentsProvider>(
          create: (_) => PaymentsProvider(),
        ),
        ChangeNotifierProvider<NavigationProvider>(
          create: (_) => NavigationProvider(),
        ),
      ],
      child: const LundriConnectApp(),
    ),
  );
}

class LundriConnectApp extends StatelessWidget {
  const LundriConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lundri Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}

class AppRoutes {
  AppRoutes._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        return _materialRoute(const SplashScreen());

      case RouteNames.login:
        return _materialRoute(const LoginScreen());

      case RouteNames.signup:
        return _materialRoute(const SignupScreen());

      case RouteNames.mainNavigation:
        return _materialRoute(const MainNavigationScreen());

      case RouteNames.requests:
        return _materialRoute(const OrdersScreen());

      case RouteNames.activeOrders:
        return _materialRoute(const ActiveOrdersScreen());

      case RouteNames.payments:
        return _materialRoute(const PaymentsScreen());

      case RouteNames.profile:
        return _materialRoute(const ProfileScreen());

      case RouteNames.businessInfo:
        return _materialRoute(const LaundryBusinessInfoScreen());

      case RouteNames.workingHours:
        return _materialRoute(const WorkingHoursScreen());

      case RouteNames.servicePricing:
        return _materialRoute(const ServicePricingScreen());

      case RouteNames.settings:
        return _materialRoute(const SettingsScreen());

      case RouteNames.support:
        return _materialRoute(const SupportScreen());

      case RouteNames.riderHome:
        return _materialRoute(const RiderHomeScreen());

      case RouteNames.operatorHome:
        return _materialRoute(const OperatorHomeScreen());

      default:
        return _materialRoute(
          const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }

  static MaterialPageRoute<dynamic> _materialRoute(Widget page) {
    return MaterialPageRoute<dynamic>(builder: (_) => page);
  }
}
