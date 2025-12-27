import 'package:go_router/go_router.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/pairing_screen.dart';
import '../../features/user_house/screens/user_house_screen.dart';
import '../../features/caregiver/screens/caregiver_timeline_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/pairing',
        name: 'pairing',
        builder: (context, state) => const PairingScreen(),
      ),
      GoRoute(
        path: '/user-house',
        name: 'user-house',
        builder: (context, state) => const UserHouseScreen(),
      ),
      GoRoute(
        path: '/caregiver-timeline',
        name: 'caregiver-timeline',
        builder: (context, state) => const CaregiverTimelineScreen(),
      ),
    ],
  );
}


