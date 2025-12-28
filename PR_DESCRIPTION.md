# Required Windows Support and NotRequired State

## Overview
This PR implements support for optional time windows, allowing users to configure which windows are required for medication reminders. Non-required windows never trigger notifications, never show as errors, and remain visually calm and neutral.

## Changes

### Core Service Updates

1. **TimeWindowService**
   - Added `getNextRequiredWindow(now, requiredWindows)` - finds the next required window after current time
   - Added `isWindowRequired(window, requiredWindows)` - checks if a window is required
   - Added TODO for per-user window time customization

2. **NotificationService**
   - Updated `updateWindowNotifications` to accept optional `requiredWindows` parameter
   - Only schedules notifications for required windows that are active and unresolved
   - Cancels notifications immediately for completed, notRequired, or non-required windows
   - Prevents any notification scheduling for notRequired windows

### UI Updates

3. **UserHouseScreen**
   - Fetches user profile to get `requiredWindows` configuration
   - Shows "Turn the lights on" CTA button only when active window is required and not completed
   - Shows calm "All good for now" state when active window is not required
   - Optionally displays "Next: <next required window>" for non-required windows
   - Passes `requiredWindows` to day stream and notification service

4. **CaregiverTimelineScreen**
   - Displays all 4 windows with visual separation:
     - Required windows: normal emphasis with action buttons
     - Not required windows: greyed out with "(Not needed)" label and reduced opacity
   - Added settings panel (gear icon in AppBar) to edit required windows:
     - Four checkboxes (Morning, Midday, Evening, Bedtime)
     - Saves to `profiles/{uid}.requiredWindows`
     - Calls `ensureDayInitialized` after saving to update day document states
   - Only allows verifying required windows (non-required windows can't be verified)

### Infrastructure

5. **App Setup**
   - Added `ProfileRepository` to app providers

6. **Code Quality**
   - Fixed deprecated API usage (`surfaceVariant` → `surfaceContainerHighest`)
   - Added TODOs for future features (per-user window times, proof escalation)

## Behavior

The app now correctly handles all scenarios:
- ✅ Midday + evening only
- ✅ One window only
- ✅ All four windows
- ✅ Non-required windows appear calm/neutral (no errors, no notifications)

## Testing

- ✅ Build compiles successfully
- ✅ All linter errors resolved
- ✅ Visual separation works correctly in caregiver timeline
- ✅ Settings panel saves and updates day documents correctly

## Future Enhancements (TODOs)

- Per-user customization of window times (stored in Profile model)
- Proof escalation based on missed required windows only
