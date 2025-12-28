import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../auth/auth_service.dart';
import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/window_repository.dart';
import '../../../../domain/models/window_state.dart';
import '../../../../domain/models/day.dart';
import '../../../../domain/models/time_window.dart';
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

  void _updateNotifications(Day? day, TimeWindow activeWindow) {
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
    
    NotificationService().updateWindowNotifications(
      window: activeWindow,
      state: windowState,
      windowInfo: windowInfo,
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

    final activeWindow = TimeWindowService.getActiveWindow();
    final todayDateKey = TimeWindowService.getTodayDateKey();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your House'),
      ),
      body: StreamBuilder(
        stream: Provider.of<WindowRepository>(context, listen: false)
            .getDayStream(_familyId!, todayDateKey),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final day = snapshot.data;
          if (day == null) {
            return const Center(child: Text('Unable to load day data.'));
          }

          final activeWindowData = day.windows[activeWindow];
          final windowState = activeWindowData?.state;

          // Determine house state from current window and completion status
          final houseState = determineHouseState(
            currentWindow: activeWindow,
            windowState: windowState,
          );

          final isCompleted = windowState == WindowState.completedSelf ||
              windowState == WindowState.completedVerified;

          // Update notifications based on window state
          // This ensures notifications are scheduled when windows become active
          // and cancelled when they're completed
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateNotifications(day, activeWindow);
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
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: isCompleted ? null : _handleTurnLightsOn,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}



