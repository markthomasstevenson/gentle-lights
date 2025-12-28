import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../auth/auth_service.dart';
import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/window_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../domain/models/window_state.dart';
import '../../../../domain/models/day.dart';
import '../../../../domain/models/time_window.dart';
import '../../../../domain/models/profile.dart';
import '../../../../services/time_window_service.dart';
import '../../../../services/notification_service.dart';
import '../widgets/house_view.dart';

class UserHouseScreen extends StatefulWidget {
  const UserHouseScreen({super.key});

  @override
  State<UserHouseScreen> createState() => _UserHouseScreenState();
}

class _UserHouseScreenState extends State<UserHouseScreen> {
  String? _familyId;
  bool _isLoading = true;
  Day? _lastDay;
  TimeWindow? _lastActiveWindow;

  @override
  void initState() {
    super.initState();
    _loadFamilyId();
  }

  void _updateNotifications(Day? day, TimeWindow activeWindow, Set<TimeWindow>? requiredWindows) {
    if (day == null) return;
    
    // Only update if day or active window changed
    if (_lastDay == day && _lastActiveWindow == activeWindow) return;
    
    _lastDay = day;
    _lastActiveWindow = activeWindow;

    final activeWindowData = day.windows[activeWindow];
    final windowState = activeWindowData?.state ?? WindowState.pending;
    final windowInfo = TimeWindowService.getActiveWindowInfo(
      windowStates: day.windows.map((key, value) => MapEntry(key, value.state)),
    );
    
    print('UserHouseScreen: Updating notifications - activeWindow=$activeWindow, windowState=$windowState, windowInfo.window=${windowInfo?.window}, windowInfo.isActive=${windowInfo?.isActive}');
    
    NotificationService().updateWindowNotifications(
      window: activeWindow,
      state: windowState,
      windowInfo: windowInfo,
      requiredWindows: requiredWindows,
    );
  }

  Future<void> _loadFamilyId() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final familyRepository =
        Provider.of<FamilyRepository>(context, listen: false);

    final user = authService.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final familyId = await familyRepository.getFamilyId(user.uid);
    setState(() {
      _familyId = familyId;
      _isLoading = false;
    });
  }

  Future<void> _handleTurnLightsOn() async {
    if (_familyId == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final windowRepository =
        Provider.of<WindowRepository>(context, listen: false);

    final user = authService.currentUser;
    if (user == null) return;

    final activeWindow = TimeWindowService.getActiveWindow();

    final success = await windowRepository.completeWindow(
      familyId: _familyId!,
      userId: user.uid,
      window: activeWindow,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lights turned on!'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_familyId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Your House'),
        ),
        body: const Center(
          child: Text('Unable to load family. Please try again.'),
        ),
      );
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your House')),
        body: const Center(child: Text('Please sign in.')),
      );
    }

    final activeWindow = TimeWindowService.getActiveWindow();
    final todayDateKey = TimeWindowService.getTodayDateKey();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your House'),
      ),
      body: StreamBuilder<Profile?>(
        stream: Provider.of<ProfileRepository>(context, listen: false)
            .getProfileStream(familyId: _familyId!, uid: user.uid),
        builder: (context, profileSnapshot) {
          // Use default required windows if profile not loaded yet
          final requiredWindows = profileSnapshot.data?.requiredWindows ?? 
                                  Profile.defaultRequiredWindows;

          return StreamBuilder<Day?>(
            stream: Provider.of<WindowRepository>(context, listen: false)
                .getDayStream(_familyId!, todayDateKey, requiredWindows: requiredWindows),
            builder: (context, daySnapshot) {
              if (daySnapshot.connectionState == ConnectionState.waiting ||
                  profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final day = daySnapshot.data;
              if (day == null) {
                return const Center(child: Text('Unable to load day data.'));
              }

              final activeWindowData = day.windows[activeWindow];
              final windowState = activeWindowData?.state;

              // Check if the active window is required
              final isActiveWindowRequired = TimeWindowService.isWindowRequired(
                activeWindow,
                requiredWindows,
              );

              // Determine house state from current window and completion status
              final houseState = determineHouseState(
                currentWindow: activeWindow,
                windowState: windowState,
              );

              final isCompleted = windowState == WindowState.completedSelf ||
                  windowState == WindowState.completedVerified;

              // Get next required window for display
              final nextRequiredWindow = TimeWindowService.getNextRequiredWindow(
                null,
                requiredWindows,
              );

              // Update notifications based on window state
              // This ensures notifications are scheduled when windows become active
              // and cancelled when they're completed
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updateNotifications(day, activeWindow, requiredWindows);
              });

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Card(
                        elevation: 4,
                        child: HouseView(state: houseState),
                      ),
                      const SizedBox(height: 48),
                      // Show CTA button only if active window is required and not completed
                      if (isActiveWindowRequired && !isCompleted)
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: _handleTurnLightsOn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: const Text('Turn the lights on'),
                          ),
                        ),
                      // Show calm state if active window is not required
                      if (!isActiveWindowRequired)
                        Column(
                          children: [
                            Text(
                              'All good for now',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (nextRequiredWindow != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Next: ${_getWindowDisplayName(nextRequiredWindow)}',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getWindowDisplayName(TimeWindow window) {
    switch (window) {
      case TimeWindow.morning:
        return 'Morning';
      case TimeWindow.midday:
        return 'Midday';
      case TimeWindow.evening:
        return 'Evening';
      case TimeWindow.bedtime:
        return 'Bedtime';
    }
  }
}



