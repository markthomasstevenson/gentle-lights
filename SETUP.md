# Gentle Lights - Setup Instructions

## Prerequisites

1. Flutter SDK (3.0.0 or higher)
2. Firebase project created in Firebase Console
3. Android Studio or VS Code with Flutter extensions

## Initial Setup

### 1. Install Dependencies

```bash
flutter pub get
```

### 2. Configure Firebase

You need to configure Firebase for both iOS and Android:

#### For Android:
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/google-services.json`

#### For iOS:
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in `ios/Runner/GoogleService-Info.plist`

#### Generate Firebase Options

Run the FlutterFire CLI to generate `firebase_options.dart`:

```bash
flutterfire configure
```

This will automatically generate the `firebase_options.dart` file with your Firebase configuration.

### 3. Update Application IDs

#### Android
Update `android/app/build.gradle`:
- `applicationId` is currently set to `com.gentlelights.app`
- Update to match your Firebase project's Android app ID

#### iOS
Update `ios/Runner.xcodeproj`:
- Bundle Identifier should match your Firebase project's iOS app ID
- Currently set to `com.example.gentleLights` in `firebase_options.dart`

## Project Structure

```
lib/
├── app/              # App configuration, router, theme
│   ├── app.dart
│   ├── router/
│   └── theme/
├── auth/             # Authentication service
├── data/             # Repositories and Firestore access
│   └── repositories/
├── domain/           # Models and enums
│   └── models/
└── features/         # Feature modules
    ├── onboarding/
    ├── user_house/
    └── caregiver/
```

## Running the App

### Android
```bash
flutter run
```

### iOS
```bash
flutter run
```

## Next Steps

1. Implement Firestore data models
2. Complete authentication flow with anonymous auth
3. Implement pairing code generation and validation
4. Build UI components for house visualization
5. Implement time window state management



