import '../domain/models/time_window.dart';

/// Service that determines the active TimeWindow based on local time
class TimeWindowService {
  /// Get the current active time window based on local time
  /// 
  /// Time windows:
  /// - Morning: 6:00 AM - 11:59 AM
  /// - Midday: 12:00 PM - 4:59 PM
  /// - Evening: 5:00 PM - 9:59 PM
  /// - Bedtime: 10:00 PM - 5:59 AM
  static TimeWindow getActiveWindow() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 6 && hour < 12) {
      return TimeWindow.morning;
    } else if (hour >= 12 && hour < 17) {
      return TimeWindow.midday;
    } else if (hour >= 17 && hour < 22) {
      return TimeWindow.evening;
    } else {
      // 22:00 - 05:59
      return TimeWindow.bedtime;
    }
  }

  /// Get today's date key in format yyyy-mm-dd
  static String getTodayDateKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Get date key for a specific date
  static String getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

