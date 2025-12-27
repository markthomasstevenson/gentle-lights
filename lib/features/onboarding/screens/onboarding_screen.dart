import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../auth/auth_service.dart';
import 'welcome_screen.dart';

/// Onboarding screen that handles initial auth and routes to welcome
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Sign in anonymously if not already signed in
    if (!authService.isAuthenticated) {
      await authService.signInAnonymously();
    }

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return const WelcomeScreen();
  }
}



