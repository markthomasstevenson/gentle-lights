import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../auth/auth_service.dart';
import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/window_repository.dart';
import '../../../../domain/models/window_state.dart';
import '../../../../services/time_window_service.dart';

class UserHouseScreen extends StatefulWidget {
  const UserHouseScreen({super.key});

  @override
  State<UserHouseScreen> createState() => _UserHouseScreenState();
}

class _UserHouseScreenState extends State<UserHouseScreen> {
  String? _familyId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFamilyId();
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
          final isLit = activeWindowData?.state == WindowState.completedSelf ||
              activeWindowData?.state == WindowState.completedVerified;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // TODO: Add house animation here (glow, curtains, etc.)
                  Card(
                    elevation: 4,
                    child: Container(
                      width: 200,
                      height: 200,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isLit
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isLit ? Icons.lightbulb : Icons.lightbulb_outline,
                            size: 64,
                            color: isLit
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isLit ? 'House: LIT' : 'House: DIM',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isLit
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // TODO: Add notification scheduling here
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: isLit ? null : _handleTurnLightsOn,
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



