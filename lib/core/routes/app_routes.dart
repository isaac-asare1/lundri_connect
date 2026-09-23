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
import '../../screens/auth screens/phone_verification_arguments.dart';
import '../../screens/auth screens/phone_verification_screen.dart';
import '../../screens/main_navigation_screen.dart';
import '../../screens/laundry/operator_home_screen.dart';
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
        return _materialRoute(const SplashScreen(), settings: settings);

      case RouteNames.login:
        return _materialRoute(const LoginScreen(), settings: settings);

      case RouteNames.signup:
        return _materialRoute(const SignupScreen(), settings: settings);

      case RouteNames.phoneVerification:
        final arguments = settings.arguments;

        if (arguments is! PhoneVerificationArguments) {
          return _errorRoute(
            'Phone verification details are missing or invalid.',
            settings: settings,
          );
        }

        return _materialRoute(
          PhoneVerificationScreen(arguments: arguments),
          settings: settings,
        );

      case RouteNames.mainNavigation:
        return _materialRoute(const MainNavigationScreen(), settings: settings);

      case RouteNames.requests:
        return _materialRoute(const OrdersScreen(), settings: settings);

      case RouteNames.activeOrders:
        return _materialRoute(const ActiveOrdersScreen(), settings: settings);

      case RouteNames.laundryProfile:
        return _materialRoute(const LaundryProfileScreen(), settings: settings);

      case RouteNames.riderProfile:
        return _materialRoute(const RiderProfileScreen(), settings: settings);

      case RouteNames.businessInfo:
        return _materialRoute(
          const LaundryBusinessInfoScreen(),
          settings: settings,
        );

      case RouteNames.workingHours:
        return _materialRoute(const WorkingHoursScreen(), settings: settings);

      case RouteNames.settings:
        return _materialRoute(const SettingsScreen(), settings: settings);

      case RouteNames.privacyPolicy:
        return _materialRoute(const PrivacyPolicyScreen(), settings: settings);

      case RouteNames.licenceAndAgreement:
        return _materialRoute(
          const LicenseAgreementScreen(),
          settings: settings,
        );

      case RouteNames.termsAndContions:
        return _materialRoute(
          const TermsAndConditionsScreen(),
          settings: settings,
        );

      case RouteNames.support:
        return _materialRoute(const SupportScreen(), settings: settings);

      case RouteNames.riderHome:
        return _materialRoute(const RiderHomeScreen(), settings: settings);

      case RouteNames.riderBusinessInfo:
        return _materialRoute(
          const RiderProfileSetupScreen(),
          settings: settings,
        );

      case RouteNames.riderHistory:
        return _materialRoute(
          const RidersOdersHistoryScreen(),
          settings: settings,
        );

      case RouteNames.laundryHistory:
        return _materialRoute(
          const LaundriesOrdersHistoryScreen(),
          settings: settings,
        );

      case RouteNames.operatorHome:
        return _materialRoute(const OperatorHomeScreen(), settings: settings);

      default:
        return _errorRoute(
          'Route not found: ${settings.name ?? 'unknown'}',
          settings: settings,
        );
    }
  }

  static MaterialPageRoute<dynamic> _materialRoute(
    Widget page, {
    RouteSettings? settings,
  }) {
    return MaterialPageRoute<dynamic>(settings: settings, builder: (_) => page);
  }

  static MaterialPageRoute<dynamic> _errorRoute(
    String message, {
    RouteSettings? settings,
  }) {
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (_) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(message, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }
}
