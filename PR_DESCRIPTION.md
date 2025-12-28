# Consistent Color System Implementation

## Overview
This PR implements a comprehensive, consistent color system for the Gentle Lights app based on the app icon palette. All colors are now centralized in `AppColors` and applied consistently across the entire application.

## Changes

### Core Color System
- **Created `AppColors` class** (`lib/app/theme/app_colors.dart`)
  - Defined all 8 core colors from the app icon palette
  - Added semantic color mappings for Material 3 color scheme
  - Included comprehensive documentation explaining color usage rules
  - Enforced `warmWindowGlow` usage restrictions (primary actions, lights on, positive feedback only)

### Theme Updates
- **Updated `AppTheme`** (`lib/app/theme/app_theme.dart`)
  - Replaced generic orange seed color with AppColors palette
  - Configured light theme with warm, non-medical color scheme
  - Configured dark theme using night/dim colors (nightSkyBlue, twilightLavender)
  - Applied colors consistently to all Material 3 components:
    - AppBar, Cards, Buttons, Input fields, Snackbars
  - Removed deprecated ColorScheme properties (surfaceVariant, background)
  - Fixed CardTheme to use CardThemeData

### Screen Updates
- **Caregiver Timeline Screen** (`lib/features/caregiver/screens/caregiver_timeline_screen.dart`)
  - Replaced hardcoded Colors (orange, blue, green, red) with AppColors
  - State colors now use: softCandleOrange (pending), twilightLavender (completed), warmWindowGlow (verified), softSageGreen (missed)
  - No red/green medical colors per design requirements

- **House View Widget** (`lib/features/user_house/widgets/house_view.dart`)
  - Replaced Colors.black with AppColors.textPrimary for shadows
  - Updated house state colors:
    - DIM: nightSkyBlue tones (unresolved, waiting)
    - WARM: warmWindowGlow (lights on, completed)
    - NIGHT: twilightLavender tones (bedtime completed)

- **All Onboarding Screens**
  - Already using theme colors, which now map to AppColors
  - Error states use softSageGreen (no red) through theme

- **User House Screen**
  - Already using theme colors correctly
  - Primary button automatically uses warmWindowGlow through theme

## Color Palette

### Core Colors
- `nightSkyBlue` (#3E4C7A) - Night/dim states
- `twilightLavender` (#7A6FB0) - Night/dim accents
- `warmWindowGlow` (#FFC857) - **PRIMARY ACTION ONLY** (buttons, lights on, positive feedback)
- `softCandleOrange` (#F6A85F) - Warm accents
- `warmOffWhite` (#FAF8F4) - Default backgrounds
- `softSageGreen` (#8FB6A6) - Subtle accents, neutral states
- `textPrimary` (#2E2E2E) - Main text
- `textSecondary` (#6F6F6F) - Secondary text

### Design Rules Enforced
- ✅ No red or green success/error colors
- ✅ warmWindowGlow restricted to primary actions, lights on, positive feedback
- ✅ Backgrounds default to warmOffWhite
- ✅ Night/dim states use nightSkyBlue and lavender tones
- ✅ All hardcoded colors replaced with AppColors references

## Testing
- ✅ Flutter analyze passes with no errors
- ✅ Debug build completes successfully
- ✅ All screens use consistent color system
- ✅ No deprecated API usage

## Files Changed
- `lib/app/theme/app_colors.dart` (new)
- `lib/app/theme/app_theme.dart` (updated)
- `lib/features/caregiver/screens/caregiver_timeline_screen.dart` (updated)
- `lib/features/user_house/widgets/house_view.dart` (updated)

## Notes
- All color usage is now centralized and consistent
- Theme automatically applies colors to Material components
- Future color additions should go through AppColors class
- If a color seems missing, leave a TODO instead of adding new colors
