# Android Build & Test Guide

This guide will help you build and test the Gentle Lights app on an Android emulator.

## Prerequisites Check

You have:
- ✅ Flutter SDK installed (3.38.5)
- ✅ Android emulator available: `Medium_Phone_API_36.1`
- ⚠️ Android SDK command-line tools need setup (optional, may not be required)

## Quick Start (Recommended)

### Step 1: Launch the Android Emulator

Launch the available emulator:

```bash
flutter emulators --launch Medium_Phone_API_36.1
```

**Alternative method (if the above doesn't work):**
1. Open Android Studio
2. Go to Tools → Device Manager
3. Start the "Medium Phone API 36.1" emulator

Wait for the emulator to fully boot (you'll see the Android home screen).

### Step 2: Verify Dependencies

Make sure all Flutter packages are installed:

```bash
flutter pub get
```

### Step 3: Build and Run the App

Once the emulator is running, build and launch the app:

```bash
flutter run
```

Flutter will automatically detect the running Android emulator and install the app.

**To build specifically for Android (if multiple devices are connected):**

```bash
flutter run -d android
```

## Alternative: Build APK for Manual Installation

If you want to build an APK file that you can install manually:

### Debug APK (for testing):
```bash
flutter build apk --debug
```

The APK will be located at: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK (optimized):
```bash
flutter build apk --release
```

The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

## Troubleshooting

### If you get Android SDK errors:

1. **Install Android Studio** (if not already installed):
   - Download from: https://developer.android.com/studio
   - Install with default settings (includes Android SDK)

2. **Set up command-line tools** (optional but recommended):
   - Open Android Studio
   - Go to Tools → SDK Manager
   - In the "SDK Tools" tab, check "Android SDK Command-line Tools"
   - Click "Apply" to install

3. **Accept Android licenses**:
   ```bash
   flutter doctor --android-licenses
   ```
   Press `y` to accept each license.

### If the emulator doesn't start:

1. **Check Android Studio Device Manager**:
   - Open Android Studio → Tools → Device Manager
   - Create a new emulator if needed
   - Make sure it's compatible with your system (x86_64 or arm64)

2. **Check virtualization**:
   - Make sure virtualization is enabled in BIOS
   - Windows: Enable Hyper-V or Windows Hypervisor Platform

### If the build fails:

1. **Check Firebase configuration**:
   - Ensure `android/app/google-services.json` exists
   - If missing, follow the setup in `SETUP.md`

2. **Clean and rebuild**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## Useful Commands

- **List available devices/emulators**: `flutter devices`
- **List all emulators**: `flutter emulators`
- **Hot reload** (while app is running): Press `r` in the terminal
- **Hot restart**: Press `R` in the terminal
- **Stop the app**: Press `q` in the terminal
- **Check Flutter setup**: `flutter doctor -v`

## Testing Workflow

1. Start emulator: `flutter emulators --launch Medium_Phone_API_36.1`
2. Run app: `flutter run`
3. Make code changes
4. Use hot reload (`r`) to see changes instantly
5. When done, press `q` to stop the app

## Next Steps

Once the app is running:
- Test the onboarding flow
- Verify Firebase connection
- Test time window functionality
- Check notification permissions


