import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lundri_connect/core/routes/route_names.dart';
import 'package:lundri_connect/core/theme/app_theme.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_routes.dart';
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
