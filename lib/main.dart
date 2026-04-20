import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lundri_connect/core/routes/app_routes.dart';
import 'package:lundri_connect/core/routes/route_names.dart';
import 'package:lundri_connect/core/theme/app_theme.dart';
import 'package:lundri_connect/firebase_options.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/orders_provider.dart';
import 'providers/payments_provider.dart';
import 'providers/rider_provider.dart';
import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        ChangeNotifierProvider<OrdersProvider>(create: (_) => OrdersProvider()),
        ChangeNotifierProvider<PaymentsProvider>(
          create: (_) => PaymentsProvider(),
        ),
        ChangeNotifierProvider<RiderProvider>(create: (_) => RiderProvider()),
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
