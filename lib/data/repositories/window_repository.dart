import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/time_window.dart';
import '../../domain/models/window_state.dart';
import '../../domain/models/day.dart';
import '../../domain/models/profile.dart';
import '../../services/time_window_service.dart';
import '../../services/notification_service.dart';

class WindowRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get the day document reference for a family and date
  DocumentReference<Map<String, dynamic>> _getDayRef(String familyId, String dateKey) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('days')
        .doc(dateKey);
  }

  /// Create a Day with windows initialized based on requiredWindows
  /// Windows that are required start as pending, others as notRequired
  Day _createDayWithRequiredWindows({
    required String dateKey,
    required Set<TimeWindow> requiredWindows,
  }) {
    return Day(
      dateKey: dateKey,
      windows: {
        for (final window in TimeWindow.values)
          window: WindowData(
            state: requiredWindows.contains(window)
                ? WindowState.pending
                : WindowState.notRequired,
            completedAt: null,
            completedByUid: null,
          ),
      },
    );
  }

  /// Mark a time window as completed by user (completedSelf)
  /// 
  /// [requiredWindows] - Optional set of required windows. If provided, used to initialize
  ///                     windows that don't exist yet. If not provided, defaults to all windows required.
  Future<bool> completeWindow({
    required String familyId,
    required String userId,
    required TimeWindow window,
    String? dateKey,
    Set<TimeWindow>? requiredWindows,
  }) async {
    try {
      final dayKey = dateKey ?? TimeWindowService.getTodayDateKey();
      final dayRef = _getDayRef(familyId, dayKey);

      // Default to all windows required if not provided
      final required = requiredWindows ?? Profile.defaultRequiredWindows;

      // Use transaction to ensure atomic update
      await _firestore.runTransaction((transaction) async {
        final dayDoc = await transaction.get(dayRef);
        
        Map<String, dynamic> windowsData;
        if (dayDoc.exists && dayDoc.data() != null) {
          windowsData = Map<String, dynamic>.from(dayDoc.data()!['windows'] ?? {});
        } else {
          windowsData = {};
        }

        // Initialize window if it doesn't exist
        // Use requiredWindows to determine initial state
        if (!windowsData.containsKey(window.name)) {
          final initialState = required.contains(window)
              ? WindowState.pending
              : WindowState.notRequired;
          windowsData[window.name] = {
            'state': initialState.name,
            'completedAt': null,
            'completedByUid': null,
          };
        }

        // Don't allow completing notRequired windows
        final currentState = windowsData[window.name]['state'] as String?;
        if (currentState == WindowState.notRequired.name) {
          throw Exception('Cannot complete a window that is not required');
        }

        // Update window state
        windowsData[window.name] = {
          'state': WindowState.completedSelf.name,
          'completedAt': FieldValue.serverTimestamp(),
          'completedByUid': userId,
        };

        // Update or create the day document
        transaction.set(dayRef, {
          'windows': windowsData,
        }, SetOptions(merge: true));

        return true;
      });

      // Cancel notifications for this window since it's now completed
      await NotificationService().updateWindowNotifications(
        window: window,
        state: WindowState.completedSelf,
      );

      return true;
    } catch (e) {
      // TODO: Handle error properly
      return false;
    }
  }

  /// Verify a window completion (caregiver action - completedVerified)
  Future<bool> verifyWindow({
    required String familyId,
    required String userId,
    required TimeWindow window,
    String? dateKey,
  }) async {
    try {
      final dayKey = dateKey ?? TimeWindowService.getTodayDateKey();
      final dayRef = _getDayRef(familyId, dayKey);

      await _firestore.runTransaction((transaction) async {
        final dayDoc = await transaction.get(dayRef);
        
        if (!dayDoc.exists) {
          throw Exception('Day document does not exist');
        }

        final data = dayDoc.data();
        if (data == null) {
          throw Exception('Day document has no data');
        }

        final windowsData = Map<String, dynamic>.from(data['windows'] ?? {});
        
        if (!windowsData.containsKey(window.name)) {
          throw Exception('Window does not exist');
        }

        // Update window state to verified
        windowsData[window.name] = {
          'state': WindowState.completedVerified.name,
          'completedAt': FieldValue.serverTimestamp(),
          'completedByUid': userId,
        };

        transaction.update(dayRef, {
          'windows': windowsData,
        });

        return true;
      });

      // Cancel notifications for this window since it's now verified
      await NotificationService().updateWindowNotifications(
        window: window,
        state: WindowState.completedVerified,
      );

      return true;
    } catch (e) {
      // TODO: Handle error properly
      return false;
    }
  }

  /// Get day document as a stream
  /// 
  /// [requiredWindows] - Optional set of required windows. If provided, used to initialize
  ///                     windows when day document doesn't exist. If not provided, defaults to all windows required.
  Stream<Day?> getDayStream(
    String familyId,
    String dateKey, {
    Set<TimeWindow>? requiredWindows,
  }) {
    final required = requiredWindows ?? Profile.defaultRequiredWindows;
    
    return _getDayRef(familyId, dateKey)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            // Return a default Day with windows initialized based on requiredWindows
            return _createDayWithRequiredWindows(
              dateKey: dateKey,
              requiredWindows: required,
            );
          }
          return Day.fromMap(snapshot.data()!, dateKey);
        });
  }

  /// Get day document once
  /// 
  /// [requiredWindows] - Optional set of required windows. If provided, used to initialize
  ///                     windows when day document doesn't exist. If not provided, defaults to all windows required.
  Future<Day?> getDay(
    String familyId,
    String dateKey, {
    Set<TimeWindow>? requiredWindows,
  }) async {
    try {
      final dayDoc = await _getDayRef(familyId, dateKey).get();
      
      if (!dayDoc.exists || dayDoc.data() == null) {
        // Return a default Day with windows initialized based on requiredWindows
        final required = requiredWindows ?? Profile.defaultRequiredWindows;
        return _createDayWithRequiredWindows(
          dateKey: dateKey,
          requiredWindows: required,
        );
      }

      return Day.fromMap(dayDoc.data()!, dateKey);
    } catch (e) {
      // TODO: Handle error properly
      return null;
    }
  }

  /// Ensure a day document exists with proper initialization based on requiredWindows
  /// This creates the document if it doesn't exist, or updates it if requiredWindows changed
  /// 
  /// Returns true if the day was created/updated, false on error
  Future<bool> ensureDayInitialized({
    required String familyId,
    required String dateKey,
    required Set<TimeWindow> requiredWindows,
  }) async {
    try {
      final dayRef = _getDayRef(familyId, dateKey);

      await _firestore.runTransaction((transaction) async {
        final dayDoc = await transaction.get(dayRef);

        Map<String, dynamic> windowsData;
        bool needsUpdate = false;

        if (dayDoc.exists && dayDoc.data() != null) {
          windowsData = Map<String, dynamic>.from(dayDoc.data()!['windows'] ?? {});
          
          // Check if any windows need to be updated based on requiredWindows change
          for (final window in TimeWindow.values) {
            final windowName = window.name;
            final windowData = windowsData[windowName] as Map<String, dynamic>?;
            final currentState = windowData != null
                ? WindowState.values.firstWhere(
                    (s) => s.name == windowData['state'],
                    orElse: () => WindowState.pending,
                  )
                : null;

            final isRequired = requiredWindows.contains(window);
            final shouldBeNotRequired = !isRequired;
            final shouldBePending = isRequired;

            // If window doesn't exist, initialize it
            if (windowData == null) {
              windowsData[windowName] = {
                'state': shouldBePending
                    ? WindowState.pending.name
                    : WindowState.notRequired.name,
                'completedAt': null,
                'completedByUid': null,
              };
              needsUpdate = true;
            }
            // If window is completed, don't change it (preserve completion)
            else if (currentState == WindowState.completedSelf ||
                     currentState == WindowState.completedVerified) {
              // Keep completion state - don't change
              continue;
            }
            // If requiredWindows changed mid-day:
            // - If newly required: set to pending (unless already completed)
            // - If newly not required: set to notRequired (unless already completed)
            else if (shouldBeNotRequired && currentState != WindowState.notRequired) {
              windowsData[windowName] = {
                'state': WindowState.notRequired.name,
                'completedAt': null,
                'completedByUid': null,
              };
              needsUpdate = true;
            } else if (shouldBePending && currentState == WindowState.notRequired) {
              windowsData[windowName] = {
                'state': WindowState.pending.name,
                'completedAt': null,
                'completedByUid': null,
              };
              needsUpdate = true;
            }
          }
        } else {
          // Day doesn't exist - create it with proper initialization
          windowsData = {};
          for (final window in TimeWindow.values) {
            windowsData[window.name] = {
              'state': requiredWindows.contains(window)
                  ? WindowState.pending.name
                  : WindowState.notRequired.name,
              'completedAt': null,
              'completedByUid': null,
            };
          }
          needsUpdate = true;
        }

        if (needsUpdate) {
          transaction.set(dayRef, {
            'windows': windowsData,
          }, SetOptions(merge: true));
        }

        return true;
      });

      return true;
    } catch (e) {
      // TODO: Handle error properly
      return false;
    }
  }
}


