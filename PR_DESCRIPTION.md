# Implement Authentication and Cross-Device Linking

## Overview
This PR implements anonymous authentication and family-based cross-device linking for the Gentle Lights app. Users can now create families, generate pairing codes for caregivers, and use recovery codes to restore access.

## Features Implemented

### 1. Anonymous Authentication
- ✅ Automatic anonymous sign-in on first launch if user is not authenticated
- ✅ AuthService updated with auth state stream support
- ✅ No email/password required (as per requirements)

### 2. Family Model & Repository
- ✅ Created `Family` and `FamilyMember` domain models
- ✅ Implemented `FamilyRepository` with full CRUD operations:
  - `createFamily()` - Creates new family with pairing and recovery codes
  - `joinFamilyWithCode()` - Allows caregivers to join via pairing code
  - `restoreFamilyWithRecoveryCode()` - Restores access using recovery code
  - `getFamilyId()` - Gets family ID for a user
  - `getFamily()` - Retrieves family document
  - `getFamilyMember()` - Gets member information
  - `getFamilyMembers()` - Lists all family members

### 3. Code Generation
- ✅ Pairing Code: 6-character human-readable code (excludes confusing characters)
- ✅ Recovery Code: 14-character code for restoring access

### 4. Onboarding Flow (User)
- ✅ Welcome Screen - Initial welcome with continue button
- ✅ Metaphor Screen - Explains the house metaphor
- ✅ Pairing Screen - Displays pairing code, allows skipping
- ✅ Recovery Screen - Displays recovery code for safekeeping
- ✅ Automatic family creation when user completes onboarding

### 5. Caregiver Join Flow
- ✅ Caregiver Join Screen - Enter pairing code and name
- ✅ Validates pairing code and adds caregiver as family member
- ✅ Role-based assignment (caregiver role)

### 6. Recovery Flow
- ✅ Recovery Restore Screen - Enter recovery code to restore access
- ✅ Supports both user and caregiver roles via query parameter
- ✅ Links current user to existing family

### 7. Firestore Security Rules
- ✅ Comprehensive security rules for families collection
- ✅ Member-based access control
- ✅ Validation for required fields
- ✅ Rules allow:
  - Read: Only family members
  - Create: Authenticated users (for new families)
  - Update: Limited to pairing/recovery codes and display names
  - Delete: Users can delete themselves

### 8. Router Updates
- ✅ Added all new onboarding routes
- ✅ Added caregiver join route
- ✅ Added recovery restore route with role parameter support

## Technical Details

### Data Structure
```
families/{familyId}
  - pairingCode: string
  - recoveryCode: string
  - createdAt: timestamp
  - members/{uid}
    - uid: string
    - role: string (user/caregiver)
    - displayName: string
    - joinedAt: timestamp
```

### Code Quality
- ✅ All code follows repository pattern
- ✅ Firestore operations abstracted behind repository
- ✅ Proper error handling (with TODOs for future enhancement)
- ✅ No linter errors
- ✅ Build passes successfully

## Files Changed

### New Files
- `lib/domain/models/family.dart` - Family and FamilyMember models
- `lib/features/onboarding/screens/welcome_screen.dart`
- `lib/features/onboarding/screens/metaphor_screen.dart`
- `lib/features/onboarding/screens/recovery_screen.dart`
- `lib/features/onboarding/screens/caregiver_join_screen.dart`
- `lib/features/onboarding/screens/recovery_restore_screen.dart`
- `firestore.rules` - Security rules

### Modified Files
- `lib/auth/auth_service.dart` - Added auth state stream
- `lib/data/repositories/family_repository.dart` - Full implementation
- `lib/app/app.dart` - Added FamilyRepository provider
- `lib/app/router/app_router.dart` - Added new routes
- `lib/features/onboarding/screens/onboarding_screen.dart` - Auto sign-in
- `lib/features/onboarding/screens/pairing_screen.dart` - Family creation
- `lib/domain/models/models.dart` - Export family models
- `firebase.json` - Added Firestore rules configuration
- `test/widget_test.dart` - Fixed test file

## Testing Notes

- ✅ Code compiles successfully
- ✅ No linter errors
- ⚠️ Manual testing required for:
  - Anonymous sign-in flow
  - Family creation
  - Pairing code validation
  - Recovery code restoration
  - Firestore security rules

## Next Steps

1. Deploy Firestore security rules to Firebase:
   ```bash
   firebase deploy --only firestore:rules
   ```

2. Test the complete flow:
   - User onboarding → family creation
   - Caregiver joining with pairing code
   - Recovery code restoration

3. Consider adding:
   - Error handling improvements (replace TODOs)
   - Loading states for better UX
   - QR code generation for pairing codes
   - Input validation enhancements

## Breaking Changes
None - this is a new feature addition.

