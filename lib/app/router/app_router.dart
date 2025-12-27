import 'package:go_router/go_router.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/metaphor_screen.dart';
import '../../features/onboarding/screens/pairing_screen.dart';
import '../../features/onboarding/screens/recovery_screen.dart';
import '../../features/onboarding/screens/caregiver_join_screen.dart';
import '../../features/onboarding/screens/recovery_restore_screen.dart';
import '../../features/user_house/screens/user_house_screen.dart';
import '../../features/caregiver/screens/caregiver_timeline_screen.dart';
import '../../domain/models/user_role.dart';

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
        path: '/onboarding/metaphor',
        name: 'metaphor',
        builder: (context, state) => const MetaphorScreen(),
      ),
      GoRoute(
        path: '/onboarding/pairing',
        name: 'pairing',
        builder: (context, state) => const PairingScreen(),
      ),
      GoRoute(
        path: '/onboarding/recovery',
        name: 'recovery',
        builder: (context, state) => const RecoveryScreen(),
      ),
      GoRoute(
        path: '/caregiver/join',
        name: 'caregiver-join',
        builder: (context, state) => const CaregiverJoinScreen(),
      ),
      GoRoute(
        path: '/recovery/restore',
        name: 'recovery-restore',
        builder: (context, state) {
          // Check for role query parameter
          final roleParam = state.uri.queryParameters['role'];
          UserRole? role;
          if (roleParam == 'caregiver') {
            role = UserRole.caregiver;
          } else if (roleParam == 'user') {
            role = UserRole.user;
          }
          return RecoveryRestoreScreen(role: role);
        },
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


