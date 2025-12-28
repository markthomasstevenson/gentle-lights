import 'package:equatable/equatable.dart';
import 'user_role.dart';
import 'time_window.dart';

/// User profile configuration stored at families/{familyId}/profiles/{uid}
/// 
/// Contains per-user settings including which time windows are required
/// for medication reminders.
class Profile extends Equatable {
  final String uid;
  final UserRole role;
  final Set<TimeWindow> requiredWindows;
  final String timeZone; // e.g., "Europe/London"
  // windowTimes can be added later for custom window times
  // For now, defaults are hardcoded in TimeWindowService

  const Profile({
    required this.uid,
    required this.role,
    required this.requiredWindows,
    required this.timeZone,
  });

  /// Default required windows (all windows)
  static const Set<TimeWindow> defaultRequiredWindows = {
    TimeWindow.morning,
    TimeWindow.midday,
    TimeWindow.evening,
    TimeWindow.bedtime,
  };

  factory Profile.fromMap(Map<String, dynamic> map, String uid) {
    // Parse requiredWindows from list of strings
    final requiredWindowsList = map['requiredWindows'] as List<dynamic>? ?? [];
    final requiredWindows = requiredWindowsList
        .map((w) => TimeWindow.values.firstWhere(
              (tw) => tw.name == w,
              orElse: () => TimeWindow.morning, // fallback
            ))
        .toSet();

    return Profile(
      uid: uid,
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.user,
      ),
      requiredWindows: requiredWindows.isEmpty
          ? defaultRequiredWindows
          : requiredWindows,
      timeZone: map['timeZone'] as String? ?? 'UTC',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role.name,
      'requiredWindows': requiredWindows.map((w) => w.name).toList(),
      'timeZone': timeZone,
    };
  }

  /// Create a default profile for a user
  factory Profile.defaultProfile({
    required String uid,
    UserRole role = UserRole.user,
  }) {
    return Profile(
      uid: uid,
      role: role,
      requiredWindows: defaultRequiredWindows,
      timeZone: 'UTC',
    );
  }

  /// Create a copy of this profile with updated fields
  Profile copyWith({
    String? uid,
    UserRole? role,
    Set<TimeWindow>? requiredWindows,
    String? timeZone,
  }) {
    return Profile(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      requiredWindows: requiredWindows ?? this.requiredWindows,
      timeZone: timeZone ?? this.timeZone,
    );
  }

  @override
  List<Object> get props => [uid, role, requiredWindows, timeZone];
}

