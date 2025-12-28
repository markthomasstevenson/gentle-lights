import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/time_window.dart';
import '../../domain/models/window_state.dart';
import '../../domain/models/day.dart';
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

  /// Mark a time window as completed by user (completedSelf)
  Future<bool> completeWindow({
    required String familyId,
    required String userId,
    required TimeWindow window,
    String? dateKey,
  }) async {
    try {
      final dayKey = dateKey ?? TimeWindowService.getTodayDateKey();
      final dayRef = _getDayRef(familyId, dayKey);

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
        if (!windowsData.containsKey(window.name)) {
          windowsData[window.name] = {
            'state': WindowState.pending.name,
            'completedAt': null,
            'completedByUid': null,
          };
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
  Stream<Day?> getDayStream(String familyId, String dateKey) {
    return _getDayRef(familyId, dateKey)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            // Return a default Day with all windows pending
            return Day(
              dateKey: dateKey,
              windows: {
                for (final window in TimeWindow.values)
                  window: const WindowData(
                    state: WindowState.pending,
                    completedAt: null,
                    completedByUid: null,
                  ),
              },
            );
          }
          return Day.fromMap(snapshot.data()!, dateKey);
        });
  }

  /// Get day document once
  Future<Day?> getDay(String familyId, String dateKey) async {
    try {
      final dayDoc = await _getDayRef(familyId, dateKey).get();
      
      if (!dayDoc.exists || dayDoc.data() == null) {
        // Return a default Day with all windows pending
        return Day(
          dateKey: dateKey,
          windows: {
            for (final window in TimeWindow.values)
              window: const WindowData(
                state: WindowState.pending,
                completedAt: null,
                completedByUid: null,
              ),
          },
        );
      }

      return Day.fromMap(dayDoc.data()!, dateKey);
    } catch (e) {
      // TODO: Handle error properly
      return null;
    }
  }
}


