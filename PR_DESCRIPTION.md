# Support for Optional Time Windows

## Overview
Extends Gentle Lights to support users who do NOT take medication in every time window. This allows per-user configuration of which windows are required, with non-required windows never nagging, never showing as missed, and remaining visually calm.

## Changes

### Domain Changes

1. **New WindowState: `notRequired`**
   - Added to `WindowState` enum
   - Represents windows that are not required for a user
   - These windows never become active, missed, or trigger notifications

2. **New Profile Model**
   - Created `Profile` model stored at `families/{familyId}/profiles/{uid}`
   - Contains:
     - `role`: UserRole (user/caregiver)
     - `requiredWindows`: Set<TimeWindow> - which windows are required
     - `timeZone`: String (store-ready, defaults to UTC for now)
   - Default profile includes all windows as required (backward compatible)

### Repository Changes

1. **ProfileRepository**
   - New repository for managing user profiles
   - Methods:
     - `getProfile()` / `getProfileStream()` - fetch user profile
     - `saveProfile()` - save/update profile
     - `updateRequiredWindows()` - update required windows config
     - `createDefaultProfile()` - create default profile

2. **WindowRepository Updates**
   - `getDay()` and `getDayStream()` now accept optional `requiredWindows` parameter
   - `completeWindow()` accepts optional `requiredWindows` parameter
   - New `ensureDayInitialized()` method that:
     - Creates day document with proper window initialization
     - Handles mid-day `requiredWindows` changes:
       - Newly required windows: set to `pending` (unless already completed)
       - Newly not-required windows: set to `notRequired` (unless already completed)
       - Completed windows are always preserved
   - Prevents completing `notRequired` windows

### State Machine Updates

1. **TimeWindowService**
   - `notRequired` windows are never active, missed, or completable
   - Only required windows can transition to missed state

2. **CaregiverInsightsService**
   - `notRequired` windows are never counted as missed
   - Only required windows contribute to missed window statistics

3. **NotificationService**
   - `notRequired` windows never trigger notifications
   - Early return for `notRequired` state to prevent any notification scheduling

### UI Updates

1. **CaregiverTimelineScreen**
   - Added `notRequired` case to `_getStateDisplayName()` switch
   - Added `notRequired` case to `_getStateColor()` switch
   - Uses subtle, calm color (softSageGreen with low opacity) for not-required state

### Testing

Added unit tests in `test/data/repositories/window_repository_required_windows_test.dart`:
- User with only midday/evening required
- User with only morning required
- All windows required (default)
- State machine rules for notRequired windows
- Conceptual tests for requiredWindows change mid-day logic

## Firestore Schema

New collection structure:
```
families/{familyId}/profiles/{uid}
{
  role: "user" | "caregiver",
  requiredWindows: ["midday", "evening"],  // Array of TimeWindow names
  timeZone: "Europe/London"
}
```

## Backward Compatibility

- Default behavior: all windows are required (existing behavior preserved)
- Existing day documents continue to work
- Profile documents are optional - if missing, defaults are used
- All existing code paths remain functional

## Implementation Notes

- Window initialization happens lazily when day documents are accessed
- `ensureDayInitialized()` should be called when profile changes to sync window states
- Completed windows are always preserved, even if `requiredWindows` changes
- `notRequired` windows cannot be completed (throws exception if attempted)

## Next Steps (Not in this PR)

- UI for configuring requiredWindows (settings screen)
- Automatic day initialization on app start
- Profile creation during onboarding
- Custom window times (structure is ready in Profile model)
