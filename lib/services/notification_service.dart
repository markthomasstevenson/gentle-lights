import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import '../domain/models/time_window.dart';
import '../domain/models/window_state.dart';
import '../app/router/app_router.dart';
import 'time_window_service.dart';

/// Service for managing gentle, persistent notifications for active time windows.
/// 
/// Notifications are designed to be calm and non-alarming:
/// - They repeat every 15 minutes while a window is active and unresolved
/// - They stop only when the window is completed
/// - They use gentle, non-medical language
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Default repeat interval for notifications (15 minutes)
  /// 
  /// This interval balances persistence with gentleness:
  /// - Frequent enough to be helpful without being annoying
  /// - Long enough to feel calm and patient
  /// - TODO: Make this configurable by user in future settings
  static const Duration defaultRepeatInterval = Duration(minutes: 15);

  /// Initialize the notification service
  /// 
  /// Must be called before scheduling any notifications.
  /// Sets up platform-specific notification channels and permissions.
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      // Initialize timezone data
      tz_data.initializeTimeZones();
      
      // Android initialization
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: false, // No sound for gentle notifications
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        // Create Android notification channel for gentle notifications
        // Using default importance for visibility, but no sound/vibration for gentleness
        const androidChannel = AndroidNotificationChannel(
          'gentle_reminders',
          'Gentle Reminders',
          description: 'Calm reminders about the house',
          importance: Importance.high, // High importance ensures visibility even when app is in foreground
          playSound: false,
          enableVibration: false,
        );

        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        
        if (androidPlugin != null) {
          // Delete existing channel if it exists (to recreate with new importance)
          // This allows us to update channel settings without requiring app reinstall
          try {
            await androidPlugin.deleteNotificationChannel(androidChannel.id);
            print('NotificationService: Deleted existing notification channel');
          } catch (e) {
            // Channel might not exist yet, that's fine
            print('NotificationService: No existing channel to delete (this is OK)');
          }
          
          // Create the notification channel with new settings
          await androidPlugin.createNotificationChannel(androidChannel);
          print('NotificationService: Notification channel created');
          
          // Request notification permission for Android 13+ (API 33+)
          final permissionGranted = await androidPlugin.requestNotificationsPermission();
          print('NotificationService: Android notification permission request result: $permissionGranted');
          
          // Also check current permission status
          final notificationsEnabled = await androidPlugin.areNotificationsEnabled();
          print('NotificationService: Android notifications currently enabled: $notificationsEnabled');
          
          if (notificationsEnabled != true) {
            print('NotificationService: WARNING - Notifications are not enabled! User needs to grant permission in settings.');
          }
          
          // Request exact alarm permission for Android 12+ (API 31+)
          // This is required for exact alarms to work when the app is closed
          await _requestExactAlarmPermission();
        }

        _initialized = true;
        return true;
      }

      return false;
    } catch (e) {
      // TODO: Log error properly
      return false;
    }
  }

  /// Request exact alarm permission for Android 12+ (API 31+)
  /// 
  /// This permission is required for scheduled notifications to work when the app is closed.
  Future<void> _requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return;
    
    try {
      const platform = MethodChannel('com.gentlelights.app/permissions');
      final bool? hasPermission = await platform.invokeMethod('canScheduleExactAlarms');
      
      if (hasPermission != true) {
        print('NotificationService: Requesting exact alarm permission');
        final bool? granted = await platform.invokeMethod('requestExactAlarmPermission');
        print('NotificationService: Exact alarm permission granted: $granted');
        
        if (granted != true) {
          print('NotificationService: WARNING - Exact alarm permission denied. Notifications may not work when app is closed.');
        }
      } else {
        print('NotificationService: Exact alarm permission already granted');
      }
    } catch (e) {
      // Permission might not be available on older Android versions, that's OK
      print('NotificationService: Could not check/request exact alarm permission: $e');
    }
  }

  /// Handle notification tap
  /// 
  /// Navigates to the user house screen when a notification is tapped.
  /// This allows users to quickly access the app and complete the window.
  void _onNotificationTapped(NotificationResponse response) {
    // Navigate to house screen using the app router
    // Using go() instead of push() to replace current route if needed
    AppRouter.router.go('/user-house');
  }

  /// Schedule a gentle notification for an active, unresolved window
  /// 
  /// The notification will:
  /// - Appear immediately when the window becomes active
  /// - Repeat every [repeatInterval] minutes (default: 15)
  /// - Continue until the window is completed
  /// 
  /// [window] - The time window to notify about
  /// [repeatInterval] - How often to repeat the notification (default: 15 minutes)
  Future<void> scheduleWindowNotification({
    required TimeWindow window,
    Duration? repeatInterval,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // Ensure exact alarm permission is granted before scheduling
    // This is especially important on Android 12+ for notifications when app is closed
    if (Platform.isAndroid) {
      await _requestExactAlarmPermission();
    }

    final interval = repeatInterval ?? defaultRepeatInterval;
    final message = _getNotificationMessage(window);

    // Generate a unique ID for this window notification
    // Using window enum index + 1000 to avoid conflicts
    final notificationId = 1000 + window.index;

    try {
      // Cancel any existing notification for this window first
      await cancelWindowNotification(window);

      // Schedule repeating notifications at the specified interval
      await _scheduleRepeatingNotifications(
        notificationId: notificationId,
        title: 'The house is still dim',
        body: message,
        window: window,
        interval: interval,
      );
    } catch (e) {
      // TODO: Log error properly
    }
  }

  /// Schedule multiple notifications at intervals
  /// 
  /// Schedules notifications for the next 24 hours at the specified interval.
  /// This ensures notifications continue until the window is resolved.
  Future<void> _scheduleRepeatingNotifications({
    required int notificationId,
    required String title,
    required String body,
    required TimeWindow window,
    required Duration interval,
  }) async {
    final now = DateTime.now();
    final currentActiveWindow = TimeWindowService.getActiveWindow();
    final windowInfo = TimeWindowService.getActiveWindowInfo();
    
    // Only schedule if this window is currently active
    // Check both the current active window and the windowInfo
    final isActiveWindow = currentActiveWindow == window;
    final windowMatches = windowInfo?.window == window;
    final isCompleted = windowInfo?.state == WindowState.completedSelf ||
                       windowInfo?.state == WindowState.completedVerified;
    
    print('NotificationService._scheduleRepeatingNotifications: window=$window, currentActiveWindow=$currentActiveWindow, isActiveWindow=$isActiveWindow, windowMatches=$windowMatches, isCompleted=$isCompleted');
    
    if (!isActiveWindow || isCompleted) {
      print('NotificationService._scheduleRepeatingNotifications: Skipping - not active or completed');
      return;
    }

    // Schedule notifications for the next 24 hours (or until window grace period ends)
    final endTime = windowInfo?.gracePeriodEnd ?? now.add(const Duration(hours: 24));
    
    // Show immediate notification first (use show() for instant display)
    try {
      print('NotificationService: Showing immediate notification for $window');
      
      // Check permissions before showing
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final enabled = await androidPlugin.areNotificationsEnabled();
        print('NotificationService: Notifications enabled check before show: $enabled');
        if (enabled != true) {
          print('NotificationService: Notifications not enabled, requesting permission');
          await androidPlugin.requestNotificationsPermission();
        }
      }
      
      await _notifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'gentle_reminders',
            'Gentle Reminders',
            channelDescription: 'Calm reminders about the house',
            importance: Importance.high, // High importance to show even when app is in foreground
            priority: Priority.high,
            playSound: false,
            enableVibration: false,
            ongoing: false,
            autoCancel: false,
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
          ),
        ),
      );
      print('NotificationService: Immediate notification shown successfully');
    } catch (e, stackTrace) {
      print('NotificationService: Error showing notification: $e');
      print('NotificationService: Stack trace: $stackTrace');
      rethrow;
    }

    // Then schedule repeating notifications
    var nextNotificationTime = now.add(interval);
    int sequenceNumber = 1; // Start from 1 since 0 is the immediate notification
    while (nextNotificationTime.isBefore(endTime)) {
      await _notifications.zonedSchedule(
        notificationId + sequenceNumber,
        title,
        body,
        _convertToTZDateTime(nextNotificationTime),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'gentle_reminders',
            'Gentle Reminders',
            channelDescription: 'Calm reminders about the house',
            importance: Importance.high, // High importance to show even when app is in foreground
            priority: Priority.high,
            playSound: false,
            enableVibration: false,
            ongoing: false,
            autoCancel: false,
            styleInformation: BigTextStyleInformation(body),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        // Removed matchDateTimeComponents - we're scheduling specific times, not recurring patterns
      );

      nextNotificationTime = nextNotificationTime.add(interval);
      sequenceNumber++;

      // Limit to prevent too many scheduled notifications
      // Schedule up to 96 notifications (24 hours / 15 minutes)
      if (sequenceNumber >= 96) break;
    }
  }

  /// Convert DateTime to TZDateTime for scheduling
  /// 
  /// Converts a local DateTime to TZDateTime in the local timezone.
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    return tz.TZDateTime(
      tz.local,
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
      dateTime.millisecond,
      dateTime.microsecond,
    );
  }

  /// Cancel all notifications for a specific window
  /// 
  /// Called when a window is completed to stop all pending notifications.
  Future<void> cancelWindowNotification(TimeWindow window) async {
    if (!_initialized) return;

    try {
      // Cancel all notification IDs for this window
      // We scheduled notifications with IDs: 1000 + window.index + sequenceNumber
      final baseId = 1000 + window.index;
      
      // Cancel notifications from baseId to baseId + 96 (max scheduled)
      for (int i = 0; i < 96; i++) {
        await _notifications.cancel(baseId + i);
      }
    } catch (e) {
      // TODO: Log error properly
    }
  }

  /// Cancel all notifications
  /// 
  /// Useful for cleanup or when user logs out.
  Future<void> cancelAllNotifications() async {
    if (!_initialized) return;

    try {
      await _notifications.cancelAll();
    } catch (e) {
      // TODO: Log error properly
    }
  }

  /// Get the appropriate notification message for a time window
  /// 
  /// Uses gentle, non-medical language consistent with the app's tone.
  String _getNotificationMessage(TimeWindow window) {
    // Rotate through gentle messages to avoid repetition
    // TODO: Make message selection configurable or more sophisticated
    final messages = [
      'The house is still dim',
      'Want to turn the lights on?',
      'A little warmth would help',
    ];

    // Use window index to select message (consistent per window)
    return messages[window.index % messages.length];
  }

  /// Check if a window needs notifications and schedule/cancel accordingly
  /// 
  /// This is the main method to call when window state changes.
  /// It will:
  /// - Schedule notifications if window is active, required, and unresolved
  /// - Cancel notifications if window is completed or not required
  /// 
  /// [window] - The time window to check
  /// [state] - Current state of the window
  /// [windowInfo] - Optional WindowInfo for additional context
  /// [requiredWindows] - Set of required windows. If provided, notifications only scheduled for required windows.
  Future<void> updateWindowNotifications({
    required TimeWindow window,
    required WindowState state,
    WindowInfo? windowInfo,
    Set<TimeWindow>? requiredWindows,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    final isCompleted = state == WindowState.completedSelf || 
                       state == WindowState.completedVerified;
    
    if (isCompleted) {
      // Window is completed - cancel all notifications immediately
      await cancelWindowNotification(window);
      return;
    }

    // Not required windows should never trigger notifications
    if (state == WindowState.notRequired) {
      await cancelWindowNotification(window);
      return;
    }

    // Check if window is required (if requiredWindows is provided)
    if (requiredWindows != null && !TimeWindowService.isWindowRequired(window, requiredWindows)) {
      // Window is not required - cancel notifications
      await cancelWindowNotification(window);
      return;
    }

    // Check if window is active and unresolved
    // Use the provided windowInfo if available, otherwise get it fresh
    final info = windowInfo ?? TimeWindowService.getActiveWindowInfo();
    
    // Check if this window is the currently active window
    final currentActiveWindow = TimeWindowService.getActiveWindow();
    final isCurrentActiveWindow = currentActiveWindow == window;
    
    // Also check if the windowInfo says this window is active
    final isActiveInInfo = info?.window == window && info?.isActive == true;
    
    // Window is active if it's the current active window OR if windowInfo says it's active
    final isActive = isCurrentActiveWindow || isActiveInInfo;
    final isUnresolved = state == WindowState.pending || state == WindowState.missed;

    // Debug: Print notification decision
    print('NotificationService: window=$window, state=$state, currentActiveWindow=$currentActiveWindow, isCurrentActiveWindow=$isCurrentActiveWindow, isActiveInInfo=$isActiveInInfo, isActive=$isActive, isUnresolved=$isUnresolved, windowInfo.window=${info?.window}, windowInfo.isActive=${info?.isActive}, isRequired=${requiredWindows?.contains(window) ?? true}');

    // Only schedule notifications for required windows that are active and unresolved
    if (isActive && isUnresolved) {
      // Window is active, required, and unresolved - schedule notifications
      print('NotificationService: Scheduling notifications for $window');
      await scheduleWindowNotification(window: window);
    } else {
      // Window is not active or is resolved - cancel notifications
      print('NotificationService: Cancelling notifications for $window (isActive=$isActive, isUnresolved=$isUnresolved)');
      await cancelWindowNotification(window);
    }
  }
}


