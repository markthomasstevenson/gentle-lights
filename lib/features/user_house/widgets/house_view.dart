import 'package:flutter/material.dart';
import '../../../../domain/models/house_state.dart';
import '../../../../domain/models/time_window.dart';
import '../../../../domain/models/window_state.dart';
import '../../../../app/theme/app_colors.dart';

/// Widget that displays the house in different visual states
/// 
/// States:
/// - DIM: Unresolved window, dim appearance
/// - WARM: Completed for current window, warm colors
/// - NIGHT: Bedtime completed, low light appearance
class HouseView extends StatelessWidget {
  final HouseState state;
  final double? width;
  final double? height;

  const HouseView({
    super.key,
    required this.state,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Determine colors and opacity based on state
    final (backgroundColor, iconColor, icon, opacity) = _getStateProperties(
      state,
      theme,
    );

    return Container(
      width: width ?? 200,
      height: height ?? 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Opacity(
        opacity: opacity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Add window glow animation here
            Icon(
              icon,
              size: 64,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            Text(
              _getStateLabel(state),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            // TODO: Add curtains animation here
            // TODO: Add chimney smoke animation here
          ],
        ),
      ),
    );
  }

  /// Get visual properties for each house state
  /// 
  /// Uses AppColors to ensure consistent color usage:
  /// - DIM: Night sky blue tones (unresolved, waiting)
  /// - WARM: Warm window glow (lights on, completed)
  /// - NIGHT: Twilight lavender tones (bedtime completed)
  (Color backgroundColor, Color iconColor, IconData icon, double opacity)
      _getStateProperties(HouseState state, ThemeData theme) {
    switch (state) {
      case HouseState.dim:
        // Dim state: night sky blue background with reduced opacity
        return (
          AppColors.nightSkyBlue.withValues(alpha: 0.3),
          AppColors.textSecondary,
          Icons.home_outlined,
          0.6,
        );
      case HouseState.warm:
        // Warm state: warm window glow background (lights on)
        return (
          AppColors.warmBackground,
          AppColors.warmWindowGlow,
          Icons.home,
          1.0,
        );
      case HouseState.night:
        // Night state: twilight lavender tones (bedtime)
        return (
          AppColors.twilightLavender.withValues(alpha: 0.3),
          AppColors.twilightLavender,
          Icons.bedtime,
          0.8,
        );
    }
  }

  /// Get label text for each house state
  String _getStateLabel(HouseState state) {
    switch (state) {
      case HouseState.dim:
        return 'House: DIM';
      case HouseState.warm:
        return 'House: WARM';
      case HouseState.night:
        return 'House: NIGHT';
    }
  }
}

/// Determines the house state based on current time window and completion status
/// 
/// Rules:
/// - NIGHT: Bedtime window is completed
/// - WARM: Current window is completed (and not bedtime)
/// - DIM: Current window is not completed
HouseState determineHouseState({
  required TimeWindow currentWindow,
  required WindowState? windowState,
}) {
  final isCompleted = windowState == WindowState.completedSelf ||
      windowState == WindowState.completedVerified;

  if (!isCompleted) {
    return HouseState.dim;
  }

  // If completed, check if it's bedtime
  if (currentWindow == TimeWindow.bedtime) {
    return HouseState.night;
  }

  return HouseState.warm;
}

