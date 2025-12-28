# MVP Functional Loop Implementation

## Overview
This PR implements the MVP functional loop for the Gentle Lights app, enabling users to mark time windows as completed and caregivers to verify completions. The implementation includes the data model, services, repositories, and UI screens with reactive Firestore streams.

## Features Implemented

### 1. Data Model
- ✅ Created `Day` model for Firestore structure: `families/{familyId}/days/{yyyy-mm-dd}`
- ✅ Each day document contains windows (morning, midday, evening, bedtime)
- ✅ Each window contains: `state`, `completedAt`, `completedByUid`
- ✅ Window states: `pending`, `completedSelf`, `completedVerified`, `missed`

### 2. Time Window Service
- ✅ `TimeWindowService` determines active window based on local time:
  - Morning: 6:00 AM - 11:59 AM
  - Midday: 12:00 PM - 4:59 PM
  - Evening: 5:00 PM - 9:59 PM
  - Bedtime: 10:00 PM - 5:59 AM
- ✅ Helper methods for date key generation (yyyy-mm-dd format)

### 3. Window Repository
- ✅ `WindowRepository` with Firestore operations:
  - `completeWindow()` - Marks window as `completedSelf` by user
  - `verifyWindow()` - Marks window as `completedVerified` by caregiver
  - `getDayStream()` - Reactive stream of day data
  - `getDay()` - One-time fetch of day data
- ✅ Uses Firestore transactions for atomic updates
- ✅ Handles missing documents gracefully (defaults to pending state)

### 4. User House Screen
- ✅ Placeholder house visual (card with "House: DIM/LIT")
- ✅ Big button: "Turn the lights on"
- ✅ On tap, marks active window as `completedSelf` and writes to Firestore
- ✅ Updates UI reactively from Firestore stream
- ✅ Shows house state based on active window completion status
- ✅ Button disabled when lights are already on
- ✅ TODO comments added for future animation and notification scheduling

### 5. Caregiver Timeline Screen
- ✅ Lists all four windows (morning, midday, evening, bedtime) and their states
- ✅ Shows window state with color indicators:
  - Pending: Orange
  - Completed: Blue
  - Verified: Green
  - Missed: Red
- ✅ Caregiver can tap "Confirm" on any pending or completed window
- ✅ Writes `completedVerified` to the window
- ✅ Shows completion timestamp when available
- ✅ TODO comments added for future timeline animation

### 6. Firestore Security Rules
- ✅ Updated rules to allow read/write access to `days` subcollection
- ✅ Only family members can read/write day documents
- ✅ Validates data structure (windows map required)

### 7. App Configuration
- ✅ Added `WindowRepository` to app providers
- ✅ Exported `Day` model in models.dart

## Technical Details

### Data Structure
```
families/{familyId}/days/{yyyy-mm-dd}
  windows: {
    morning: { state, completedAt, completedByUid },
    midday: { state, completedAt, completedByUid },
    evening: { state, completedAt, completedByUid },
    bedtime: { state, completedAt, completedByUid }
  }
```

### Reactive Updates
- Both screens use `StreamBuilder` to reactively update when Firestore data changes
- Real-time synchronization across devices for the same family

### Error Handling
- Graceful handling of missing family IDs
- Default pending state for missing day documents
- User-friendly error messages via SnackBar

## Files Changed

### New Files
- `lib/domain/models/day.dart` - Day and WindowData models
- `lib/services/time_window_service.dart` - Active window determination service

### Modified Files
- `lib/data/repositories/window_repository.dart` - Full Firestore implementation
- `lib/features/user_house/screens/user_house_screen.dart` - Complete UI with stream
- `lib/features/caregiver/screens/caregiver_timeline_screen.dart` - Complete UI with verification
- `lib/app/app.dart` - Added WindowRepository provider
- `lib/domain/models/models.dart` - Exported Day model
- `firestore.rules` - Added days subcollection rules

## Verification

- ✅ All prompt requirements met exactly
- ✅ Flutter analyze passes with no issues
- ✅ Build succeeds (tested with `flutter build apk --debug`)
- ✅ No linter errors
- ✅ Firestore rules updated and validated
- ✅ TODO comments added for future enhancements

## Testing Notes

- ✅ Code compiles successfully
- ✅ No linter errors
- ⚠️ Manual testing recommended for:
  - Firestore read/write operations
  - Real-time stream updates
  - Time window transitions
  - Cross-device synchronization
  - Firestore security rules

## Future Enhancements (TODOs Added)

1. **Animations** (marked in code):
   - House glow animation when lights turn on
   - Window animations in caregiver timeline
   - Smooth state transitions

2. **Notification Scheduling** (marked in code):
   - Gentle notifications that repeat until resolved
   - Time-based notification triggers
   - Notification scheduling service

## Breaking Changes
None - this is a new feature implementation that doesn't affect existing functionality.
