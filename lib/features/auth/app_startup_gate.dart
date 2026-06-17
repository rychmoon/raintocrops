import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/features/auth/login.dart';
import '/features/presentation/home/screens/main_screen.dart';
import '/features/presentation/home/screens/onboarding_screen.dart';
import '/features/presentation/home/widgets/cloud_indicator.dart';

class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  late Future<Widget> _startupFlow;

  @override
  void initState() {
    super.initState();
    _startupFlow = _handleStartup();
  }

  Future<Widget> _handleStartup() async {
    final prefs = await SharedPreferences.getInstance();

    final bool hasSeenOnboarding =
        prefs.getBool('hasSeenOnboarding') ?? false;

    if (!hasSeenOnboarding) {
      return const OnboardingScreen();
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    // SESSION EXPIRATION CHECK
    // Example: force login again after 3 days
    const int sessionExpiryDays = 3;

    final int? lastLoginMillis = prefs.getInt('lastLoginAt');
    if (lastLoginMillis == null) {
      await FirebaseAuth.instance.signOut();
      return const LoginScreen();
    }

    final lastLogin = DateTime.fromMillisecondsSinceEpoch(lastLoginMillis);
    final now = DateTime.now();
    final difference = now.difference(lastLogin);

    if (difference.inDays >= sessionExpiryDays) {
      await FirebaseAuth.instance.signOut();
      await prefs.remove('lastLoginAt');
      return const LoginScreen();
    }

    return const MainScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _startupFlow,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFFF6F6F6),
            body: Center(
              child: CustomLoadingAnimation(size: 120),
            ),
          );
        }

        return snapshot.data ?? const LoginScreen();
      },
    );
  }
}