import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../auth/auth_service.dart';
import '../../../../data/repositories/family_repository.dart';
import '../../../../domain/models/user_role.dart';
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
    final familyRepository = Provider.of<FamilyRepository>(context, listen: false);
    
    // Sign in anonymously if not already signed in
    if (!authService.isAuthenticated) {
      await authService.signInAnonymously();
    }

    final user = authService.currentUser;
    if (user != null) {
      // Check if user has already completed onboarding (has a family)
      final familyId = await familyRepository.getFamilyId(user.uid);
      if (familyId != null) {
        // User has a family, check their role and redirect
        final member = await familyRepository.getFamilyMember(familyId, user.uid);
        if (member != null && mounted) {
          // Redirect based on role
          if (member.role == UserRole.caregiver) {
            context.go('/caregiver-timeline');
            return;
          } else {
            context.go('/user-house');
            return;
          }
        }
      }
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



