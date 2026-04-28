import 'package:flutter/material.dart';
import 'package:lundri_connect/core/routes/route_names.dart';
import 'package:lundri_connect/screens/laundry/laundry_business_info_screen.dart'
    show LaundryBusinessInfoScreen;
import 'package:lundri_connect/screens/others/licence_and_agreement.dart';
import 'package:lundri_connect/screens/others/privacy_policy.dart';
import 'package:lundri_connect/screens/rider/rider_business_info_screen.dart';
import 'package:lundri_connect/screens/others/orders_history_screen.dart';
import 'package:lundri_connect/screens/others/terms_and_conditons.dart';

import '../../screens/laundry/laundry_profile_screen.dart';
import '../../screens/laundry/working_hours_screen.dart';
import '../../screens/rider/active_orders_screen.dart';
import '../../screens/auth screens/login_screen.dart';
import '../../screens/main_navigation_screen.dart';
import '../../screens/laundry/operator_home_screen.dart';
import '../../screens/others/payments_screen.dart';
import '../../screens/laundry/requests_screen.dart';
import '../../screens/rider/rider_home_screen.dart';
import '../../screens/rider/rider_profile_screen.dart';
import '../../screens/others/settings_screen.dart';
import '../../screens/auth screens/signup_screen.dart';
import '../../screens/others/splash_screen.dart';
import '../../screens/others/support_screen.dart';

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

      case RouteNames.laundryProfile:
        return _materialRoute(const LaundryProfileScreen());

      case RouteNames.riderProfile:
        return _materialRoute(const RiderProfileScreen());

      case RouteNames.businessInfo:
        return _materialRoute(const LaundryBusinessInfoScreen());

      case RouteNames.workingHours:
        return _materialRoute(const WorkingHoursScreen());

      case RouteNames.settings:
        return _materialRoute(const SettingsScreen());

      case RouteNames.privacyPolicy:
        return _materialRoute(const PrivacyPolicyScreen());

      case RouteNames.licenceAndAgreement:
        return _materialRoute(const LicenseAgreementScreen());

      case RouteNames.termsAndContions:
        return _materialRoute(const TermsAndConditionsScreen());

      case RouteNames.support:
        return _materialRoute(const SupportScreen());

      case RouteNames.riderHome:
        return _materialRoute(const RiderHomeScreen());

      case RouteNames.riderBusinessInfo:
        return _materialRoute(const RiderProfileSetupScreen());

      case RouteNames.riderHistory:
        return _materialRoute(const RidersOdersHistoryScreen());

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
