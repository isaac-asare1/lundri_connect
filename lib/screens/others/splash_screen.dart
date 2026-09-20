import 'package:flutter/material.dart';

import '../../core/routes/route_names.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color _backgroundColor = Color(0xFFFF6B4A);

  @override
  void initState() {
    super.initState();
    _goNext();
  }

  Future<void> _goNext() async {
    await Future<void>.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image(
                image: AssetImage('assets/icons/lundri_connect_logo.png'),
                width: 155,
                height: 155,
                fit: BoxFit.contain,
              ),

              SizedBox(height: 24),

              Text(
                'Lundri Connect',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),

              SizedBox(height: 40),

              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
