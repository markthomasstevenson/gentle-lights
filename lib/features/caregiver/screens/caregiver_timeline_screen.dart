import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../auth/auth_service.dart';
import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/window_repository.dart';
import '../../../../domain/models/time_window.dart';
import '../../../../domain/models/window_state.dart';
import '../../../../services/time_window_service.dart';
import '../../../../services/caregiver_insights_service.dart';
import '../../../../app/theme/app_colors.dart';

class CaregiverTimelineScreen extends StatefulWidget {
  const CaregiverTimelineScreen({super.key});

  @override
  State<CaregiverTimelineScreen> createState() =>
      _CaregiverTimelineScreenState();
}

class _CaregiverTimelineScreenState extends State<CaregiverTimelineScreen> {
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

  Future<void> _handleVerifyWindow(TimeWindow window) async {
    if (_familyId == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final windowRepository =
        Provider.of<WindowRepository>(context, listen: false);

    final user = authService.currentUser;
    if (user == null) return;

    final success = await windowRepository.verifyWindow(
      familyId: _familyId!,
      userId: user.uid,
      window: window,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${window.name} window confirmed'),
          duration: const Duration(seconds: 2),
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

  String _getStateDisplayName(WindowState state) {
    switch (state) {
      case WindowState.pending:
        return 'Pending';
      case WindowState.completedSelf:
        return 'Completed';
      case WindowState.completedVerified:
        return 'Verified';
      case WindowState.missed:
        return 'Missed';
      case WindowState.notRequired:
        return 'Not Required';
    }
  }

  /// Get color for window state indicator
  /// 
  /// Uses app color palette - no red/green medical colors
  Color _getStateColor(WindowState state) {
    switch (state) {
      case WindowState.pending:
        // Pending state uses soft candle orange (warm, waiting)
        return AppColors.softCandleOrange;
      case WindowState.completedSelf:
        // Self-completed uses twilight lavender (neutral completion)
        return AppColors.twilightLavender;
      case WindowState.completedVerified:
        // Verified uses warm window glow (positive completion)
        return AppColors.warmWindowGlow;
      case WindowState.missed:
        // Missed uses soft sage green (neutral, not red)
        return AppColors.softSageGreen;
      case WindowState.notRequired:
        // Not required uses a very subtle, calm color (e.g., light gray)
        // This should be visually calm and not draw attention
        return AppColors.softSageGreen.withValues(alpha: 0.3);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Caregiver Timeline')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_familyId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Caregiver Timeline')),
        body: const Center(
          child: Text('Unable to load family. Please try again.'),
        ),
      );
    }

    final todayDateKey = TimeWindowService.getTodayDateKey();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver Timeline'),
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

          // TODO: Add timeline animation here
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Today\'s Windows',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              for (final window in TimeWindow.values)
                Builder(
                  builder: (context) {
                    final windowData = day.windows[window];
                    final state = windowData?.state ?? WindowState.pending;
                    final canVerify = state == WindowState.pending ||
                        state == WindowState.completedSelf;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          _getWindowDisplayName(window),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _getStateColor(state),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(_getStateDisplayName(state)),
                              ],
                            ),
                            if (windowData?.completedAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Completed: ${windowData!.completedAt!.toString().substring(0, 16)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: canVerify
                            ? ElevatedButton(
                                onPressed: () => _handleVerifyWindow(window),
                                child: const Text('Confirm'),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              const SizedBox(height: 32),
              // Insights section
              FutureBuilder<CaregiverInsights>(
                future: CaregiverInsightsService()
                    .getInsights(familyId: _familyId!),
                builder: (context, insightsSnapshot) {
                  if (insightsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }

                  if (insightsSnapshot.hasError || !insightsSnapshot.hasData) {
                    return const SizedBox.shrink();
                  }

                  final insights = insightsSnapshot.data!;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Insights',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      // Missed windows count
                      if (insights.missedCountLast7Days > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '${insights.missedCountLast7Days} windows missed over the last week',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      // Most frequently missed window hint
                      if (insights.mostFrequentlyMissedWindow == TimeWindow.evening)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Evenings are often delayed',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      // Today's missed windows
                      Builder(
                        builder: (context) {
                          final missedToday = <TimeWindow>[];
                          final todayWindows = TimeWindowService.getTodayWindows(
                            windowStates: day.windows.map(
                              (key, value) => MapEntry(key, value.state),
                            ),
                          );
                          
                          for (final windowInfo in todayWindows) {
                            final windowData = day.windows[windowInfo.window];
                            final state = windowData?.state ?? WindowState.pending;
                            
                            // Count as missed if explicitly marked or logically missed
                            if (state == WindowState.missed || windowInfo.isMissed) {
                              missedToday.add(windowInfo.window);
                            }
                          }
                          
                          if (missedToday.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Missed today: ${missedToday.map((w) => _getWindowDisplayName(w)).join(", ")}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}


