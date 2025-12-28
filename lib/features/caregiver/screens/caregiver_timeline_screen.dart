import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../auth/auth_service.dart';
import '../../../../data/repositories/family_repository.dart';
import '../../../../data/repositories/window_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../domain/models/time_window.dart';
import '../../../../domain/models/window_state.dart';
import '../../../../domain/models/profile.dart';
import '../../../../domain/models/day.dart';
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
  String? _targetUserId; // The user whose profile we're viewing/editing
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
    if (familyId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Find the first user (role: user) in the family to view/edit their profile
    final firestore = FirebaseFirestore.instance;
    final membersQuery = await firestore
        .collection('families')
        .doc(familyId)
        .collection('members')
        .where('role', isEqualTo: 'user')
        .limit(1)
        .get();

    String? targetUserId;
    if (membersQuery.docs.isNotEmpty) {
      targetUserId = membersQuery.docs.first.id;
    }

    setState(() {
      _familyId = familyId;
      _targetUserId = targetUserId;
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
        actions: [
          // Settings button to edit required windows
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _targetUserId != null
                ? () => _showRequiredWindowsSettings(context)
                : null,
            tooltip: 'Edit Required Windows',
          ),
        ],
      ),
      body: StreamBuilder<Profile?>(
        stream: _targetUserId != null
            ? Provider.of<ProfileRepository>(context, listen: false)
                .getProfileStream(familyId: _familyId!, uid: _targetUserId!)
            : Stream<Profile?>.value(null),
        builder: (context, profileSnapshot) {
          final requiredWindows = profileSnapshot.data?.requiredWindows ??
              Profile.defaultRequiredWindows;

          return StreamBuilder<Day?>(
            stream: Provider.of<WindowRepository>(context, listen: false)
                .getDayStream(_familyId!, todayDateKey, requiredWindows: requiredWindows),
            builder: (context, daySnapshot) {
              if (daySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final day = daySnapshot.data;
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
                        final isRequired = TimeWindowService.isWindowRequired(
                          window,
                          requiredWindows,
                        );
                        final canVerify = (state == WindowState.pending ||
                                state == WindowState.completedSelf) &&
                            isRequired; // Only allow verifying required windows

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: isRequired
                              ? null
                              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(
                                  _getWindowDisplayName(window),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isRequired
                                        ? null
                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (!isRequired) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '(Not needed)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
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
          );
        },
      ),
    );
  }

  Future<void> _showRequiredWindowsSettings(BuildContext context) async {
    if (_familyId == null || _targetUserId == null) return;

    final profileRepository =
        Provider.of<ProfileRepository>(context, listen: false);

    // Get current profile
    final currentProfile = await profileRepository.getProfile(
      familyId: _familyId!,
      uid: _targetUserId!,
    );

    final currentRequiredWindows =
        currentProfile?.requiredWindows ?? Profile.defaultRequiredWindows;

    // Create a copy for editing
    final selectedWindows = Set<TimeWindow>.from(currentRequiredWindows);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => _RequiredWindowsSettingsDialog(
        selectedWindows: selectedWindows,
        onSave: (windows) async {
          // Save to profile
          final success = await profileRepository.updateRequiredWindows(
            familyId: _familyId!,
            uid: _targetUserId!,
            requiredWindows: windows,
          );

          if (!mounted) return;

          if (success) {
            // Update today's day document to reflect the new required windows
            final windowRepository =
                Provider.of<WindowRepository>(context, listen: false);
            final todayDateKey = TimeWindowService.getTodayDateKey();
            await windowRepository.ensureDayInitialized(
              familyId: _familyId!,
              dateKey: todayDateKey,
              requiredWindows: windows,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Required windows updated'),
                  duration: Duration(seconds: 2),
                ),
              );
              Navigator.of(context).pop();
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to update required windows. Please try again.'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        },
      ),
    );
  }
}

class _RequiredWindowsSettingsDialog extends StatefulWidget {
  final Set<TimeWindow> selectedWindows;
  final Function(Set<TimeWindow>) onSave;

  const _RequiredWindowsSettingsDialog({
    required this.selectedWindows,
    required this.onSave,
  });

  @override
  State<_RequiredWindowsSettingsDialog> createState() =>
      _RequiredWindowsSettingsDialogState();
}

class _RequiredWindowsSettingsDialogState
    extends State<_RequiredWindowsSettingsDialog> {
  late Set<TimeWindow> _selectedWindows;

  @override
  void initState() {
    super.initState();
    _selectedWindows = Set<TimeWindow>.from(widget.selectedWindows);
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Required Windows'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Select which time windows are required:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          for (final window in TimeWindow.values)
            CheckboxListTile(
              title: Text(_getWindowDisplayName(window)),
              value: _selectedWindows.contains(window),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedWindows.add(window);
                  } else {
                    _selectedWindows.remove(window);
                  }
                });
              },
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => widget.onSave(_selectedWindows),
          child: const Text('Save'),
        ),
      ],
    );
  }
}


