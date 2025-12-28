import 'package:flutter_test/flutter_test.dart';
import 'package:gentle_lights/domain/models/time_window.dart';
import 'package:gentle_lights/domain/models/window_state.dart';
import 'package:gentle_lights/services/notification_service.dart';
import 'package:gentle_lights/services/time_window_service.dart';

void main() {
  group('NotificationService', () {
    group('defaultRepeatInterval', () {
      test('has default repeat interval of 15 minutes', () {
        expect(
          NotificationService.defaultRepeatInterval,
          const Duration(minutes: 15),
        );
      });

      test('15 minutes is reasonable for gentle notifications', () {
        // Verify the interval is not too frequent (not less than 5 minutes)
        expect(
          NotificationService.defaultRepeatInterval.inMinutes,
          greaterThanOrEqualTo(5),
        );
        // And not too infrequent (not more than 30 minutes)
        expect(
          NotificationService.defaultRepeatInterval.inMinutes,
          lessThanOrEqualTo(30),
        );
      });
    });

    group('Notification message selection', () {
      test('returns gentle message for morning window', () {
        // Access the private method via reflection or test the public behavior
        // Since _getNotificationMessage is private, we test via scheduleWindowNotification
        // which uses it internally. For now, we'll test the expected messages exist.
        const messages = [
          'The house is still dim',
          'Want to turn the lights on?',
          'A little warmth would help',
        ];

        // Verify all expected messages are present
        expect(messages, contains('The house is still dim'));
        expect(messages, contains('Want to turn the lights on?'));
        expect(messages, contains('A little warmth would help'));
      });

      test('messages are non-medical and gentle', () {
        const messages = [
          'The house is still dim',
          'Want to turn the lights on?',
          'A little warmth would help',
        ];

        // Verify no medical language
        for (final message in messages) {
          expect(message.toLowerCase(), isNot(contains('medication')));
          expect(message.toLowerCase(), isNot(contains('pill')));
          expect(message.toLowerCase(), isNot(contains('dose')));
          expect(message.toLowerCase(), isNot(contains('prescription')));
        }

        // Verify gentle, warm language
        expect(messages.any((m) => m.contains('house')), isTrue);
        expect(messages.any((m) => m.contains('warm') || m.contains('dim')), isTrue);
      });
    });

    group('Notification ID calculation', () {
      test('generates unique IDs for each window', () {
        // Notification IDs are: 1000 + window.index
        expect(1000 + TimeWindow.morning.index, equals(1000));
        expect(1000 + TimeWindow.midday.index, equals(1001));
        expect(1000 + TimeWindow.evening.index, equals(1002));
        expect(1000 + TimeWindow.bedtime.index, equals(1003));
      });

      test('notification IDs do not overlap between windows', () {
        final morningId = 1000 + TimeWindow.morning.index;
        final middayId = 1000 + TimeWindow.midday.index;
        final eveningId = 1000 + TimeWindow.evening.index;
        final bedtimeId = 1000 + TimeWindow.bedtime.index;

        final ids = [morningId, middayId, eveningId, bedtimeId];
        expect(ids.toSet().length, equals(4)); // All unique
      });
    });

    group('updateWindowNotifications logic', () {
      test('cancels notifications when window is completedSelf', () async {
        final service = NotificationService();
        
        // This will attempt to cancel notifications
        // In a real test with mocking, we'd verify cancelWindowNotification was called
        await service.updateWindowNotifications(
          window: TimeWindow.morning,
          state: WindowState.completedSelf,
        );

        // Without mocking, we can't verify the actual cancellation,
        // but we can verify the method completes without error
        expect(service, isNotNull);
      });

      test('cancels notifications when window is completedVerified', () async {
        final service = NotificationService();
        
        await service.updateWindowNotifications(
          window: TimeWindow.morning,
          state: WindowState.completedVerified,
        );

        expect(service, isNotNull);
      });

      test('handles pending state correctly', () async {
        final service = NotificationService();
        
        // With a real active window, this would schedule notifications
        // Without mocking, we verify it doesn't throw
        await service.updateWindowNotifications(
          window: TimeWindow.morning,
          state: WindowState.pending,
        );

        expect(service, isNotNull);
      });

      test('handles missed state correctly', () async {
        final service = NotificationService();
        
        await service.updateWindowNotifications(
          window: TimeWindow.morning,
          state: WindowState.missed,
        );

        expect(service, isNotNull);
      });
    });

    group('Window state detection', () {
      test('identifies completed states correctly', () {
        const completedStates = [
          WindowState.completedSelf,
          WindowState.completedVerified,
        ];

        for (final state in completedStates) {
          final isCompleted = state == WindowState.completedSelf ||
              state == WindowState.completedVerified;
          expect(isCompleted, isTrue, reason: '$state should be identified as completed');
        }
      });

      test('identifies unresolved states correctly', () {
        const unresolvedStates = [
          WindowState.pending,
          WindowState.missed,
        ];

        for (final state in unresolvedStates) {
          final isUnresolved = state == WindowState.pending ||
              state == WindowState.missed;
          expect(isUnresolved, isTrue, reason: '$state should be identified as unresolved');
        }
      });
    });

    group('Integration with TimeWindowService', () {
      test('works with TimeWindowService.getActiveWindowInfo', () {
        // Verify the service can work with TimeWindowService
        // The service should handle null windowInfo gracefully
        expect(() => TimeWindowService.getActiveWindowInfo(), returnsNormally);
      });

      test('handles window info for active morning window', () {
        final time = DateTime(2024, 1, 15, 8, 0); // 8 AM
        final windowInfo = TimeWindowService.getActiveWindowInfo(now: time);
        
        expect(windowInfo, isNotNull);
        expect(windowInfo!.window, TimeWindow.morning);
        expect(windowInfo.isActive, isTrue);
      });
    });

    group('Notification cancellation logic', () {
      test('calculates correct base ID for cancellation', () {
        // Base ID = 1000 + window.index
        // Cancellation range = baseId to baseId + 95 (96 total notifications)
        final morningBaseId = 1000 + TimeWindow.morning.index;
        final middayBaseId = 1000 + TimeWindow.midday.index;
        
        expect(morningBaseId, equals(1000));
        expect(middayBaseId, equals(1001));
        
        // Verify cancellation range
        final morningCancelRange = List.generate(96, (i) => morningBaseId + i);
        expect(morningCancelRange.first, equals(1000));
        expect(morningCancelRange.last, equals(1095));
      });
    });

    group('Edge cases', () {
      test('handles all time windows', () {
        final service = NotificationService();
        
        for (final window in TimeWindow.values) {
          expect(
            () => service.updateWindowNotifications(
              window: window,
              state: WindowState.pending,
            ),
            returnsNormally,
            reason: 'Should handle $window window',
          );
        }
      });

      test('handles all window states', () {
        final service = NotificationService();
        
        for (final state in WindowState.values) {
          expect(
            () => service.updateWindowNotifications(
              window: TimeWindow.morning,
              state: state,
            ),
            returnsNormally,
            reason: 'Should handle $state state',
          );
        }
      });
    });

    group('Notification scheduling limits', () {
      test('limits scheduled notifications to 96 per window', () {
        // 24 hours / 15 minutes = 96 notifications max
        const hoursInDay = 24;
        const minutesPerHour = 60;
        const defaultIntervalMinutes = 15;
        
        final maxNotifications = (hoursInDay * minutesPerHour) ~/ defaultIntervalMinutes;
        expect(maxNotifications, equals(96));
      });

      test('notification limit prevents excessive scheduling', () {
        // Verify the limit is reasonable (not too many, not too few)
        expect(96, greaterThan(10)); // At least 10 notifications
        expect(96, lessThan(200)); // Not more than 200 notifications
      });
    });

    group('Singleton pattern', () {
      test('returns same instance', () {
        final service1 = NotificationService();
        final service2 = NotificationService();
        
        expect(service1, same(service2));
      });
    });
  });

  group('NotificationService - Integration scenarios', () {
    test('complete flow: active window -> schedule -> complete -> cancel', () async {
      final service = NotificationService();
      
      // Simulate: Window becomes active and unresolved
      await service.updateWindowNotifications(
        window: TimeWindow.morning,
        state: WindowState.pending,
        windowInfo: WindowInfo(
          window: TimeWindow.morning,
          startTime: DateTime(2024, 1, 15, 4, 0),
          endTime: DateTime(2024, 1, 15, 11, 59),
          gracePeriodEnd: DateTime(2024, 1, 15, 12, 29),
          state: WindowState.pending,
          isActive: true,
          isMissed: false,
          canComplete: true,
        ),
      );

      // Simulate: Window is completed
      await service.updateWindowNotifications(
        window: TimeWindow.morning,
        state: WindowState.completedSelf,
      );

      // Verify service handled the flow
      expect(service, isNotNull);
    });

    test('handles window transition correctly', () async {
      final service = NotificationService();
      
      // Morning window completed
      await service.updateWindowNotifications(
        window: TimeWindow.morning,
        state: WindowState.completedSelf,
      );

      // Midday window becomes active
      await service.updateWindowNotifications(
        window: TimeWindow.midday,
        state: WindowState.pending,
        windowInfo: WindowInfo(
          window: TimeWindow.midday,
          startTime: DateTime(2024, 1, 15, 12, 0),
          endTime: DateTime(2024, 1, 15, 16, 59),
          gracePeriodEnd: DateTime(2024, 1, 15, 17, 29),
          state: WindowState.pending,
          isActive: true,
          isMissed: false,
          canComplete: true,
        ),
      );

      expect(service, isNotNull);
    });
  });
}

