import '../domain/models/time_window.dart';
import '../domain/models/window_state.dart';

/// Information about a time window including its state and timing
class WindowInfo {
  final TimeWindow window;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime gracePeriodEnd;
  final WindowState state;
  final bool isActive;
  final bool isMissed;
  final bool canComplete; // Can still be completed even if missed

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

/// Service that determines time windows, their states, and handles grace periods
/// 
/// Time windows:
/// - Morning: 04:00 – 11:59
/// - Midday: 12:00 – 16:59
/// - Evening: 17:00 – 21:59
/// - Bedtime: 22:00 – 03:59 (next day)
/// 
/// TODO: Add per-user customization of window times
///   - Store window times in Profile model (windowTimes field)
///   - Update _getWindowForTime to use user-specific times
///   - Allow caregivers to configure custom window times per user
class TimeWindowService {
  /// Default grace period in minutes (30 minutes)
  static const int defaultGracePeriodMinutes = 30;

  /// Get the current active time window based on local time
  /// 
  /// Returns the window that is currently active (within its time range or grace period)
  static TimeWindow getActiveWindow([DateTime? now]) {
    final currentTime = now ?? DateTime.now();
    return _getWindowForTime(currentTime);
  }

  /// Get the time window for a specific time
  static TimeWindow _getWindowForTime(DateTime time) {
    final hour = time.hour;

    // Morning: 04:00 – 11:59
    if (hour >= 4 && hour < 12) {
      return TimeWindow.morning;
    }
    // Midday: 12:00 – 16:59
    else if (hour >= 12 && hour < 17) {
      return TimeWindow.midday;
    }
    // Evening: 17:00 – 21:59
    else if (hour >= 17 && hour < 22) {
      return TimeWindow.evening;
    }
    // Bedtime: 22:00 – 03:59 (spans midnight)
    else {
      // 22:00-23:59 or 00:00-03:59
      return TimeWindow.bedtime;
    }
  }

  /// Get the start time for a window on a given date
  /// 
  /// For bedtime window, the start time is on the same day (22:00)
  /// For other windows, start time is on the same day
  static DateTime _getWindowStartTime(TimeWindow window, DateTime date) {
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
  /// 
  /// For bedtime window, the end time is on the next day (03:59)
  /// For other windows, end time is on the same day
  static DateTime _getWindowEndTime(TimeWindow window, DateTime date) {
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

  /// Get all windows for today with their states
  /// 
  /// Returns a list of WindowInfo objects for all windows, ordered chronologically.
  /// Each window's state is determined based on:
  /// - Current time vs window timing
  /// - Whether the window has been completed
  /// - Grace period logic
  /// 
  /// [now] - Optional current time (for testing)
  /// [windowStates] - Map of window states from Day model (optional, defaults to all pending)
  /// [gracePeriodMinutes] - Grace period in minutes (defaults to 30)
  static List<WindowInfo> getTodayWindows({
    DateTime? now,
    Map<TimeWindow, WindowState>? windowStates,
    int gracePeriodMinutes = defaultGracePeriodMinutes,
  }) {
    final currentTime = now ?? DateTime.now();
    final today = DateTime(currentTime.year, currentTime.month, currentTime.day);
    
    // Default all windows to pending if not provided
    final states = windowStates ?? {
      for (final window in TimeWindow.values) window: WindowState.pending,
    };

    final windows = <WindowInfo>[];

    // Process windows in chronological order
    // Morning, Midday, Evening are on the same day
    // Bedtime spans midnight, so we need to handle it carefully

    // Morning: 04:00 – 11:59 (same day)
    final morningStart = _getWindowStartTime(TimeWindow.morning, today);
    final morningEnd = _getWindowEndTime(TimeWindow.morning, today);
    final morningGraceEnd = morningEnd.add(Duration(minutes: gracePeriodMinutes));
    final morningState = states[TimeWindow.morning] ?? WindowState.pending;
    final morningInfo = _createWindowInfo(
      TimeWindow.morning,
      morningStart,
      morningEnd,
      morningGraceEnd,
      morningState,
      currentTime,
    );
    windows.add(morningInfo);

    // Midday: 12:00 – 16:59 (same day)
    final middayStart = _getWindowStartTime(TimeWindow.midday, today);
    final middayEnd = _getWindowEndTime(TimeWindow.midday, today);
    final middayGraceEnd = middayEnd.add(Duration(minutes: gracePeriodMinutes));
    final middayState = states[TimeWindow.midday] ?? WindowState.pending;
    final middayInfo = _createWindowInfo(
      TimeWindow.midday,
      middayStart,
      middayEnd,
      middayGraceEnd,
      middayState,
      currentTime,
    );
    windows.add(middayInfo);

    // Evening: 17:00 – 21:59 (same day)
    // If we're in early morning (before 4 AM), we should check yesterday's evening window
    // (which is missed), not today's (which is future)
    // Evening grace period ends at 22:29 (21:59 + 30 min), so if hour < 23, check yesterday
    // For simplicity: if hour < 4, use yesterday's evening
    final eveningDate = currentTime.hour < 4 
        ? today.subtract(const Duration(days: 1)) 
        : today;
    final eveningStart = _getWindowStartTime(TimeWindow.evening, eveningDate);
    final eveningEnd = _getWindowEndTime(TimeWindow.evening, eveningDate);
    final eveningGraceEnd = eveningEnd.add(Duration(minutes: gracePeriodMinutes));
    final eveningState = states[TimeWindow.evening] ?? WindowState.pending;
    final eveningInfo = _createWindowInfo(
      TimeWindow.evening,
      eveningStart,
      eveningEnd,
      eveningGraceEnd,
      eveningState,
      currentTime,
    );
    windows.add(eveningInfo);

    // Bedtime: 22:00 – 03:59 (spans midnight)
    // Determine which bedtime window is relevant:
    // - If we're at or before 5:00 AM, use yesterday's bedtime (covers active window, grace period, and just-missed state)
    // - At 6:00 AM or later, use today's bedtime (which starts at 22:00 today)
    // This ensures at 5:00 AM we check yesterday's missed bedtime, not today's future one
    final bedtimeDate = currentTime.hour <= 5 
        ? today.subtract(const Duration(days: 1)) 
        : today;
    final bedtimeStart = _getWindowStartTime(TimeWindow.bedtime, bedtimeDate);
    final bedtimeEnd = _getWindowEndTime(TimeWindow.bedtime, bedtimeDate);
    final bedtimeGraceEnd = bedtimeEnd.add(Duration(minutes: gracePeriodMinutes));
    // For bedtime window state, if we're checking yesterday's window, we need to get
    // the state from yesterday's date key, but for simplicity in MVP, we use today's state
    // (In a full implementation, you'd pass states for both today and yesterday)
    final bedtimeState = states[TimeWindow.bedtime] ?? WindowState.pending;
    final bedtimeInfo = _createWindowInfo(
      TimeWindow.bedtime,
      bedtimeStart,
      bedtimeEnd,
      bedtimeGraceEnd,
      bedtimeState,
      currentTime,
    );
    windows.add(bedtimeInfo);

    return windows;
  }

  /// Create a WindowInfo object with calculated state
  static WindowInfo _createWindowInfo(
    TimeWindow window,
    DateTime startTime,
    DateTime endTime,
    DateTime gracePeriodEnd,
    WindowState state,
    DateTime currentTime,
  ) {
    // If not required, it's never active, missed, or completable
    if (state == WindowState.notRequired) {
      return WindowInfo(
        window: window,
        startTime: startTime,
        endTime: endTime,
        gracePeriodEnd: gracePeriodEnd,
        state: state,
        isActive: false,
        isMissed: false,
        canComplete: false, // Not required windows cannot be completed
      );
    }

    // If already completed, it's not active or missed
    final isCompleted = state == WindowState.completedSelf || 
                        state == WindowState.completedVerified;
    
    if (isCompleted) {
      return WindowInfo(
        window: window,
        startTime: startTime,
        endTime: endTime,
        gracePeriodEnd: gracePeriodEnd,
        state: state,
        isActive: false,
        isMissed: false,
        canComplete: false, // Already completed
      );
    }

    // Determine if window is currently active
    // Active if current time is between start and grace period end
    final isActive = currentTime.isAfter(startTime.subtract(const Duration(seconds: 1))) &&
                     currentTime.isBefore(gracePeriodEnd.add(const Duration(seconds: 1)));

    // Determine if window is missed
    // Missed if grace period has passed and not completed
    // Only required windows can be missed (notRequired windows are handled above)
    final isMissed = currentTime.isAfter(gracePeriodEnd);

    // Can complete if:
    // - Window is active (within grace period), OR
    // - Window is missed but we allow completing missed windows (MVP: allow it)
    // For MVP, we allow completing missed windows to support irregular sleep patterns
    final canComplete = isActive || isMissed;

    return WindowInfo(
      window: window,
      startTime: startTime,
      endTime: endTime,
      gracePeriodEnd: gracePeriodEnd,
      state: state,
      isActive: isActive,
      isMissed: isMissed,
      canComplete: canComplete,
    );
  }

  /// Get today's date key in format yyyy-mm-dd
  static String getTodayDateKey() {
    final now = DateTime.now();
    return getDateKey(now);
  }

  /// Get date key for a specific date
  static String getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get the active window info for the current time
  /// 
  /// Returns the WindowInfo for the currently active window, or null if no window is active
  static WindowInfo? getActiveWindowInfo({
    DateTime? now,
    Map<TimeWindow, WindowState>? windowStates,
    int gracePeriodMinutes = defaultGracePeriodMinutes,
  }) {
    final windows = getTodayWindows(
      now: now,
      windowStates: windowStates,
      gracePeriodMinutes: gracePeriodMinutes,
    );
    
    return windows.firstWhere(
      (info) => info.isActive,
      orElse: () => windows.firstWhere(
        (info) => info.canComplete && 
                  info.state != WindowState.completedSelf && 
                  info.state != WindowState.completedVerified,
        orElse: () => windows.first,
      ),
    );
  }

  /// Check if a window is required based on the requiredWindows set
  /// 
  /// Returns true if the window is in the requiredWindows set
  static bool isWindowRequired(TimeWindow window, Set<TimeWindow> requiredWindows) {
    return requiredWindows.contains(window);
  }

  /// Get the next required window after the current time
  /// 
  /// Returns the next window from requiredWindows that will occur after [now],
  /// or null if no more required windows are coming today.
  /// 
  /// [now] - Current time (optional, defaults to DateTime.now())
  /// [requiredWindows] - Set of required windows to check
  static TimeWindow? getNextRequiredWindow(
    DateTime? now,
    Set<TimeWindow> requiredWindows,
  ) {
    final currentTime = now ?? DateTime.now();
    final activeWindow = getActiveWindow(currentTime);
    
    // Get all windows in chronological order
    final allWindows = [
      TimeWindow.morning,
      TimeWindow.midday,
      TimeWindow.evening,
      TimeWindow.bedtime,
    ];
    
    // Find the index of the active window
    final activeIndex = allWindows.indexOf(activeWindow);
    
    // Check windows starting from the next one after active
    for (int i = 1; i < allWindows.length; i++) {
      final nextIndex = (activeIndex + i) % allWindows.length;
      final nextWindow = allWindows[nextIndex];
      
      // If this is a required window, return it
      if (requiredWindows.contains(nextWindow)) {
        return nextWindow;
      }
    }
    
    // If we've checked all windows and none are required, return null
    // (This shouldn't happen if at least one window is required, but handle gracefully)
    return null;
  }
}
