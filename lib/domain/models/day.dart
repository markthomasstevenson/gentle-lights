import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'time_window.dart';
import 'window_state.dart';

class Day extends Equatable {
  final String dateKey; // Format: yyyy-mm-dd
  final Map<TimeWindow, WindowData> windows;

  const Day({
    required this.dateKey,
    required this.windows,
  });

  factory Day.fromMap(Map<String, dynamic> map, String dateKey) {
    final windowsMap = <TimeWindow, WindowData>{};
    
    if (map['windows'] != null) {
      final windowsData = map['windows'] as Map<String, dynamic>;
      
      for (final windowName in TimeWindow.values) {
        if (windowsData[windowName.name] != null) {
          final windowMap = windowsData[windowName.name] as Map<String, dynamic>;
          windowsMap[windowName] = WindowData.fromMap(windowMap);
        } else {
          // Default to pending if not present
          windowsMap[windowName] = const WindowData(
            state: WindowState.pending,
            completedAt: null,
            completedByUid: null,
          );
        }
      }
    } else {
      // Initialize all windows as pending if no data
      for (final window in TimeWindow.values) {
        windowsMap[window] = const WindowData(
          state: WindowState.pending,
          completedAt: null,
          completedByUid: null,
        );
      }
    }

    return Day(
      dateKey: dateKey,
      windows: windowsMap,
    );
  }

  Map<String, dynamic> toMap() {
    final windowsMap = <String, dynamic>{};
    for (final entry in windows.entries) {
      windowsMap[entry.key.name] = entry.value.toMap();
    }

    return {
      'windows': windowsMap,
    };
  }

  @override
  List<Object> get props => [dateKey, windows];
}

class WindowData extends Equatable {
  final WindowState state;
  final DateTime? completedAt;
  final String? completedByUid;

  const WindowData({
    required this.state,
    this.completedAt,
    this.completedByUid,
  });

  factory WindowData.fromMap(Map<String, dynamic> map) {
    return WindowData(
      state: WindowState.values.firstWhere(
        (e) => e.name == map['state'],
        orElse: () => WindowState.pending,
      ),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      completedByUid: map['completedByUid'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'state': state.name,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'completedByUid': completedByUid,
    };
  }

  @override
  List<Object?> get props => [state, completedAt, completedByUid];
}

