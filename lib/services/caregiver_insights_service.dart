import '../domain/models/day.dart';
import '../domain/models/time_window.dart';
import '../domain/models/window_state.dart';
import '../data/repositories/window_repository.dart';
import 'time_window_service.dart';

/// Result containing caregiver insights
class CaregiverInsights {
  final int missedCountLast7Days;
  final TimeWindow? mostFrequentlyMissedWindow;
  final Map<TimeWindow, int> missedCountByWindow;

  const CaregiverInsights({
    required this.missedCountLast7Days,
    this.mostFrequentlyMissedWindow,
    required this.missedCountByWindow,
  });
}

/// Service for computing caregiver insights and patterns
/// 
/// TODO: Add proof escalation based on missed required windows only
///   - Only count missed windows that are in requiredWindows set
///   - Escalate proof level (Level 0 → Level 1 → Level 2) when required windows are missed
///   - Reset proof level when user successfully completes required windows consistently
///   - Store proof level in Profile model
class CaregiverInsightsService {
  final WindowRepository _windowRepository;

  CaregiverInsightsService({WindowRepository? windowRepository})
      : _windowRepository = windowRepository ?? WindowRepository();

  /// Get insights for a family over the last 7 days
  /// 
  /// Computes:
  /// - Total missed windows count over last 7 days
  /// - Most frequently missed window
  Future<CaregiverInsights> getInsights({
    required String familyId,
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    final today = DateTime(currentTime.year, currentTime.month, currentTime.day);
    
    // Get date keys for last 7 days (including today)
    final dateKeys = <String>[];
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      dateKeys.add(TimeWindowService.getDateKey(date));
    }

    // Fetch all days
    final days = <Day>[];
    for (final dateKey in dateKeys) {
      final day = await _windowRepository.getDay(familyId, dateKey);
      if (day != null) {
        days.add(day);
      }
    }

    // Count missed windows
    final missedCountByWindow = <TimeWindow, int>{
      for (final window in TimeWindow.values) window: 0,
    };
    int totalMissedCount = 0;

    for (final day in days) {
      final dayDate = _parseDateKey(day.dateKey);
      for (final window in TimeWindow.values) {
        final windowData = day.windows[window];
        if (windowData == null) continue;

        // Count as missed if:
        // 1. State is explicitly marked as missed, OR
        // 2. State is pending and the window's grace period has passed
        final isMissed = _isWindowMissed(
          windowData.state,
          window,
          dayDate,
          currentTime,
        );

        if (isMissed) {
          missedCountByWindow[window] = (missedCountByWindow[window] ?? 0) + 1;
          totalMissedCount++;
        }
      }
    }

    // Find most frequently missed window
    TimeWindow? mostFrequentlyMissed;
    int maxMissedCount = 0;
    for (final entry in missedCountByWindow.entries) {
      if (entry.value > maxMissedCount) {
        maxMissedCount = entry.value;
        mostFrequentlyMissed = entry.key;
      }
    }

    return CaregiverInsights(
      missedCountLast7Days: totalMissedCount,
      mostFrequentlyMissedWindow: maxMissedCount > 0 ? mostFrequentlyMissed : null,
      missedCountByWindow: missedCountByWindow,
    );
  }

  /// Determine if a window is missed based on state and time
  bool _isWindowMissed(
    WindowState state,
    TimeWindow window,
    DateTime dayDate,
    DateTime currentTime,
  ) {
    // Not required windows are never missed
    if (state == WindowState.notRequired) {
      return false;
    }

    // Explicitly marked as missed
    if (state == WindowState.missed) {
      return true;
    }

    // If completed, it's not missed
    if (state == WindowState.completedSelf || state == WindowState.completedVerified) {
      return false;
    }

    // For pending windows, check if grace period has passed
    if (state == WindowState.pending) {
      // For historical days (before today), pending windows are considered missed
      // since the grace period must have passed
      final today = DateTime(currentTime.year, currentTime.month, currentTime.day);
      final windowDay = DateTime(dayDate.year, dayDate.month, dayDate.day);
      
      if (windowDay.isBefore(today)) {
        // Historical day: pending = missed
        return true;
      } else if (windowDay.isAtSameMomentAs(today)) {
        // Today: check if grace period has passed
        final windowInfo = _getWindowInfoForDay(window, dayDate, currentTime);
        return windowInfo.isMissed;
      } else {
        // Future day: not missed yet
        return false;
      }
    }

    return false;
  }

  /// Get WindowInfo for a specific day's window
  /// This is a simplified version that works with historical dates
  WindowInfo _getWindowInfoForDay(
    TimeWindow window,
    DateTime dayDate,
    DateTime currentTime,
  ) {
    // Calculate window timing for the given day
    final startTime = _getWindowStartTime(window, dayDate);
    final endTime = _getWindowEndTime(window, dayDate);
    final gracePeriodEnd = endTime.add(
      const Duration(minutes: TimeWindowService.defaultGracePeriodMinutes),
    );

    // Determine if missed based on current time
    final isMissed = currentTime.isAfter(gracePeriodEnd);

    return WindowInfo(
      window: window,
      startTime: startTime,
      endTime: endTime,
      gracePeriodEnd: gracePeriodEnd,
      state: WindowState.pending,
      isActive: false,
      isMissed: isMissed,
      canComplete: false,
    );
  }

  /// Get the start time for a window on a given date
  DateTime _getWindowStartTime(TimeWindow window, DateTime date) {
    final year = date.year;
    final month = date.month;
    final day = date.day;

    switch (window) {
      case TimeWindow.morning:
        return DateTime(year, month, day, 4, 0);
      case TimeWindow.midday:
        return DateTime(year, month, day, 12, 0);
      case TimeWindow.evening:
        return DateTime(year, month, day, 17, 0);
      case TimeWindow.bedtime:
        return DateTime(year, month, day, 22, 0);
    }
  }

  /// Get the end time for a window on a given date
  DateTime _getWindowEndTime(TimeWindow window, DateTime date) {
    final year = date.year;
    final month = date.month;
    final day = date.day;

    switch (window) {
      case TimeWindow.morning:
        return DateTime(year, month, day, 11, 59);
      case TimeWindow.midday:
        return DateTime(year, month, day, 16, 59);
      case TimeWindow.evening:
        return DateTime(year, month, day, 21, 59);
      case TimeWindow.bedtime:
        // Bedtime ends at 03:59 the next day
        final nextDay = date.add(const Duration(days: 1));
        return DateTime(nextDay.year, nextDay.month, nextDay.day, 3, 59);
    }
  }

  /// Parse date key (yyyy-mm-dd) to DateTime
  DateTime _parseDateKey(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) {
      throw FormatException('Invalid date key format: $dateKey');
    }
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}

/// Simplified WindowInfo for insights calculation
class WindowInfo {
  final TimeWindow window;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime gracePeriodEnd;
  final WindowState state;
  final bool isActive;
  final bool isMissed;
  final bool canComplete;

  const WindowInfo({
    required this.window,
    required this.startTime,
    required this.endTime,
    required this.gracePeriodEnd,
    required this.state,
    required this.isActive,
    required this.isMissed,
    required this.canComplete,
  });
}

