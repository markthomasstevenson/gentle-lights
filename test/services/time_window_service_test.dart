import 'package:flutter_test/flutter_test.dart';
import 'package:gentle_lights/domain/models/time_window.dart';
import 'package:gentle_lights/domain/models/window_state.dart';
import 'package:gentle_lights/services/time_window_service.dart';

void main() {
  group('TimeWindowService', () {
    group('getActiveWindow', () {
      test('returns morning window for 6:00 AM', () {
        final time = DateTime(2024, 1, 15, 6, 0);
        expect(TimeWindowService.getActiveWindow(time), TimeWindow.morning);
      });

      test('returns morning window for 4:00 AM (start of morning)', () {
        final time = DateTime(2024, 1, 15, 4, 0);
        expect(TimeWindowService.getActiveWindow(time), TimeWindow.morning);
      });

      test('returns morning window for 11:59 AM (end of morning)', () {
        final time = DateTime(2024, 1, 15, 11, 59);
        expect(TimeWindowService.getActiveWindow(time), TimeWindow.morning);
      });

      test('returns midday window for 12:00 PM', () {
        final time = DateTime(2024, 1, 15, 12, 0);
        expect(TimeWindowService.getActiveWindow(time), TimeWindow.midday);
      });

      test('returns midday window for 4:59 PM (end of midday)', () {
        final time = DateTime(2024, 1, 15, 16, 59);
        expect(TimeWindowService.getActiveWindow(time), TimeWindow.midday);
      });

      test('returns evening window for 5:00 PM', () {
        final time = DateTime(2024, 1, 15, 17, 0);
        expect(TimeWindowService.getActiveWindow(time), TimeWindow.evening);
      });

      test('returns evening window for 9:59 PM (end of evening)', () {
        final time = DateTime(2024, 1, 15, 21, 59);
        expect(TimeWindowService.getActiveWindow(time), TimeWindow.evening);
      });

      test('returns bedtime window for 10:00 PM', () {
        final time = DateTime(2024, 1, 15, 22, 0);
        expect(TimeWindowService.getActiveWindow(time), TimeWindow.bedtime);
      });

      test('returns bedtime window for 11:59 PM', () {
        final time = DateTime(2024, 1, 15, 23, 59);
        expect(TimeWindowService.getActiveWindow(time), TimeWindow.bedtime);
      });

      test('returns bedtime window for midnight (00:00)', () {
        final time = DateTime(2024, 1, 16, 0, 0);
        expect(TimeWindowService.getActiveWindow(time), TimeWindow.bedtime);
      });

      test('returns bedtime window for 3:59 AM (end of bedtime)', () {
        final time = DateTime(2024, 1, 16, 3, 59);
        expect(TimeWindowService.getActiveWindow(time), TimeWindow.bedtime);
      });

      test('returns morning window for 4:00 AM after bedtime', () {
        final time = DateTime(2024, 1, 16, 4, 0);
        expect(TimeWindowService.getActiveWindow(time), TimeWindow.morning);
      });
    });

    group('getTodayWindows', () {
      test('returns all four windows in chronological order', () {
        final time = DateTime(2024, 1, 15, 10, 0); // 10 AM
        final windows = TimeWindowService.getTodayWindows(now: time);

        expect(windows.length, 4);
        expect(windows[0].window, TimeWindow.morning);
        expect(windows[1].window, TimeWindow.midday);
        expect(windows[2].window, TimeWindow.evening);
        expect(windows[3].window, TimeWindow.bedtime);
      });

      test('morning window has correct start and end times', () {
        final time = DateTime(2024, 1, 15, 10, 0);
        final windows = TimeWindowService.getTodayWindows(now: time);
        final morning = windows.firstWhere((w) => w.window == TimeWindow.morning);

        expect(morning.startTime, DateTime(2024, 1, 15, 4, 0));
        expect(morning.endTime, DateTime(2024, 1, 15, 11, 59));
        expect(morning.gracePeriodEnd, DateTime(2024, 1, 15, 12, 29)); // 11:59 + 30 min
      });

      test('bedtime window spans midnight correctly', () {
        final time = DateTime(2024, 1, 15, 23, 0);
        final windows = TimeWindowService.getTodayWindows(now: time);
        final bedtime = windows.firstWhere((w) => w.window == TimeWindow.bedtime);

        expect(bedtime.startTime, DateTime(2024, 1, 15, 22, 0));
        expect(bedtime.endTime, DateTime(2024, 1, 16, 3, 59)); // Next day
        expect(bedtime.gracePeriodEnd, DateTime(2024, 1, 16, 4, 29)); // 3:59 + 30 min
      });

      test('active window is correctly identified during morning', () {
        final time = DateTime(2024, 1, 15, 8, 0); // 8 AM
        final windows = TimeWindowService.getTodayWindows(now: time);
        final morning = windows.firstWhere((w) => w.window == TimeWindow.morning);

        expect(morning.isActive, isTrue);
        expect(morning.isMissed, isFalse);
        expect(morning.canComplete, isTrue);
      });

      test('window is active during grace period', () {
        final time = DateTime(2024, 1, 15, 12, 15); // 12:15 PM (15 min into grace period)
        final windows = TimeWindowService.getTodayWindows(now: time);
        final morning = windows.firstWhere((w) => w.window == TimeWindow.morning);

        expect(morning.isActive, isTrue); // Still within grace period
        expect(morning.canComplete, isTrue);
      });

      test('window is missed after grace period', () {
        final time = DateTime(2024, 1, 15, 12, 31); // 12:31 PM (after grace period)
        final windows = TimeWindowService.getTodayWindows(now: time);
        final morning = windows.firstWhere((w) => w.window == TimeWindow.morning);

        expect(morning.isActive, isFalse);
        expect(morning.isMissed, isTrue);
        expect(morning.canComplete, isTrue); // Can still complete missed windows
      });

      test('completed window is not active or missed', () {
        final time = DateTime(2024, 1, 15, 10, 0);
        final windowStates = {
          TimeWindow.morning: WindowState.completedSelf,
        };
        final windows = TimeWindowService.getTodayWindows(
          now: time,
          windowStates: windowStates,
        );
        final morning = windows.firstWhere((w) => w.window == TimeWindow.morning);

        expect(morning.state, WindowState.completedSelf);
        expect(morning.isActive, isFalse);
        expect(morning.isMissed, isFalse);
        expect(morning.canComplete, isFalse);
      });

      test('verified window is not active or missed', () {
        final time = DateTime(2024, 1, 15, 10, 0);
        final windowStates = {
          TimeWindow.morning: WindowState.completedVerified,
        };
        final windows = TimeWindowService.getTodayWindows(
          now: time,
          windowStates: windowStates,
        );
        final morning = windows.firstWhere((w) => w.window == TimeWindow.morning);

        expect(morning.state, WindowState.completedVerified);
        expect(morning.isActive, isFalse);
        expect(morning.isMissed, isFalse);
        expect(morning.canComplete, isFalse);
      });
    });

    group('Edge cases - Late night usage', () {
      test('bedtime window is active at 2:00 AM', () {
        final time = DateTime(2024, 1, 16, 2, 0); // 2 AM next day
        final windows = TimeWindowService.getTodayWindows(now: time);
        final bedtime = windows.firstWhere((w) => w.window == TimeWindow.bedtime);

        expect(bedtime.isActive, isTrue);
        expect(bedtime.canComplete, isTrue);
      });

      test('bedtime window is active at 3:30 AM (during grace period)', () {
        final time = DateTime(2024, 1, 16, 3, 30); // 3:30 AM
        final windows = TimeWindowService.getTodayWindows(now: time);
        final bedtime = windows.firstWhere((w) => w.window == TimeWindow.bedtime);

        expect(bedtime.isActive, isTrue); // Still within grace period (ends at 4:29)
        expect(bedtime.canComplete, isTrue);
      });

      test('bedtime window is missed after grace period at 5:00 AM', () {
        final time = DateTime(2024, 1, 16, 5, 0); // 5 AM
        final windows = TimeWindowService.getTodayWindows(now: time);
        final bedtime = windows.firstWhere((w) => w.window == TimeWindow.bedtime);

        expect(bedtime.isActive, isFalse);
        expect(bedtime.isMissed, isTrue);
        expect(bedtime.canComplete, isTrue); // Can still complete
      });
    });

    group('Edge cases - After midnight', () {
      test('correctly handles transition from bedtime to morning', () {
        // 3:59 AM - still bedtime
        final bedtimeTime = DateTime(2024, 1, 16, 3, 59);
        expect(TimeWindowService.getActiveWindow(bedtimeTime), TimeWindow.bedtime);

        // 4:00 AM - morning starts
        final morningTime = DateTime(2024, 1, 16, 4, 0);
        expect(TimeWindowService.getActiveWindow(morningTime), TimeWindow.morning);
      });

      test('bedtime window from previous day is still accessible at 1:00 AM', () {
        final time = DateTime(2024, 1, 16, 1, 0); // 1 AM on Jan 16
        final windows = TimeWindowService.getTodayWindows(now: time);
        final bedtime = windows.firstWhere((w) => w.window == TimeWindow.bedtime);

        // Bedtime started on Jan 15 at 22:00, ends Jan 16 at 3:59
        expect(bedtime.startTime.day, 15);
        expect(bedtime.endTime.day, 16);
        expect(bedtime.isActive, isTrue);
      });
    });

    group('Edge cases - Custom grace period', () {
      test('uses custom grace period when provided', () {
        final time = DateTime(2024, 1, 15, 12, 45); // 12:45 PM
        final windows = TimeWindowService.getTodayWindows(
          now: time,
          gracePeriodMinutes: 60, // 60 minute grace period
        );
        final morning = windows.firstWhere((w) => w.window == TimeWindow.morning);

        // Morning ends at 11:59, grace period ends at 12:59 with 60 min grace
        expect(morning.gracePeriodEnd, DateTime(2024, 1, 15, 12, 59));
        expect(morning.isActive, isTrue); // Still within 60 min grace period
      });

      test('window is missed after custom grace period', () {
        final time = DateTime(2024, 1, 15, 13, 0); // 1:00 PM
        final windows = TimeWindowService.getTodayWindows(
          now: time,
          gracePeriodMinutes: 60,
        );
        final morning = windows.firstWhere((w) => w.window == TimeWindow.morning);

        expect(morning.isActive, isFalse);
        expect(morning.isMissed, isTrue);
      });
    });

    group('getActiveWindowInfo', () {
      test('returns active window info during morning', () {
        final time = DateTime(2024, 1, 15, 8, 0);
        final activeInfo = TimeWindowService.getActiveWindowInfo(now: time);

        expect(activeInfo, isNotNull);
        expect(activeInfo!.window, TimeWindow.morning);
        expect(activeInfo.isActive, isTrue);
      });

      test('returns window info even if no window is currently active', () {
        // At 4:00 AM, morning just started, but if we're checking at 3:30 AM
        // during bedtime grace period, we should get bedtime
        final time = DateTime(2024, 1, 16, 3, 30);
        final activeInfo = TimeWindowService.getActiveWindowInfo(now: time);

        expect(activeInfo, isNotNull);
        expect(activeInfo!.window, TimeWindow.bedtime);
        expect(activeInfo.isActive, isTrue);
      });
    });

    group('getDateKey', () {
      test('returns correct date key format', () {
        final date = DateTime(2024, 1, 15);
        expect(TimeWindowService.getDateKey(date), '2024-01-15');
      });

      test('pads single digit months and days', () {
        final date = DateTime(2024, 3, 5);
        expect(TimeWindowService.getDateKey(date), '2024-03-05');
      });

      test('handles year boundaries correctly', () {
        final date = DateTime(2023, 12, 31);
        expect(TimeWindowService.getDateKey(date), '2023-12-31');
      });
    });

    group('getTodayDateKey', () {
      test('returns date key for current date', () {
        final key = TimeWindowService.getTodayDateKey();
        expect(key, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      });
    });

    group('Irregular sleep patterns support', () {
      test('allows completing missed morning window in the afternoon', () {
        final time = DateTime(2024, 1, 15, 14, 0); // 2 PM
        final windowStates = {
          TimeWindow.morning: WindowState.pending,
        };
        final windows = TimeWindowService.getTodayWindows(
          now: time,
          windowStates: windowStates,
        );
        final morning = windows.firstWhere((w) => w.window == TimeWindow.morning);

        expect(morning.isMissed, isTrue);
        expect(morning.canComplete, isTrue); // Can still complete
      });

      test('allows completing missed evening window late at night', () {
        final time = DateTime(2024, 1, 16, 1, 0); // 1 AM next day
        final windows = TimeWindowService.getTodayWindows(now: time);
        final evening = windows.firstWhere((w) => w.window == TimeWindow.evening);

        expect(evening.isMissed, isTrue);
        expect(evening.canComplete, isTrue); // Can still complete
      });
    });

    group('Daylight Savings Time (basic test)', () {
      test('handles DST transition day correctly', () {
        // Spring forward: March 10, 2024 (2 AM becomes 3 AM)
        // This is a basic test - in real implementation, DateTime handles DST automatically
        final time = DateTime(2024, 3, 10, 8, 0);
        final windows = TimeWindowService.getTodayWindows(now: time);
        
        expect(windows.length, 4);
        expect(windows[0].window, TimeWindow.morning);
        
        // The service should work correctly as DateTime handles DST automatically
        final activeWindow = TimeWindowService.getActiveWindow(time);
        expect(activeWindow, TimeWindow.morning);
      });

      test('handles fall back DST transition', () {
        // Fall back: November 3, 2024 (2 AM becomes 1 AM)
        final time = DateTime(2024, 11, 3, 8, 0);
        final windows = TimeWindowService.getTodayWindows(now: time);
        
        expect(windows.length, 4);
        final activeWindow = TimeWindowService.getActiveWindow(time);
        expect(activeWindow, TimeWindow.morning);
      });
    });

    group('Multiple windows state handling', () {
      test('handles mix of completed and pending windows', () {
        final time = DateTime(2024, 1, 15, 14, 0); // 2 PM
        final windowStates = {
          TimeWindow.morning: WindowState.completedSelf,
          TimeWindow.midday: WindowState.pending,
          TimeWindow.evening: WindowState.pending,
          TimeWindow.bedtime: WindowState.pending,
        };
        final windows = TimeWindowService.getTodayWindows(
          now: time,
          windowStates: windowStates,
        );

        final morning = windows.firstWhere((w) => w.window == TimeWindow.morning);
        final midday = windows.firstWhere((w) => w.window == TimeWindow.midday);

        expect(morning.state, WindowState.completedSelf);
        expect(morning.isActive, isFalse);
        expect(midday.state, WindowState.pending);
        expect(midday.isActive, isTrue); // Currently in midday window
      });
    });
  });
}

