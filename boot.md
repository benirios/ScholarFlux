# How to run the app on iOS simulator

From the `mobile` directory, run these commands:

```bash
cd /Users/beni/Dev/ScholarFlux/mobile

# Boot the simulator (only if it's not already running)
xcrun simctl boot "iPhone 17 Pro" || true
open -a Simulator

# Run the Flutter app on the simulator
flutter pub get
flutter run -d "iPhone 17 Pro"
```

If you ever see `No devices found`, re-run the `xcrun simctl boot "iPhone 17 Pro"` and `open -a Simulator` commands, then try `flutter run` again.

xcrun simctl boot "iPhone 17 Pro" || true
open -a Simulator
flutter pub get
flutter run -d "iPhone 17 Pro"

# How to run the app on Android emulator

From the `mobile` directory, run these commands:

```bash
cd /Users/beni/Dev/ScholarFlux/mobile

# List available emulators
$HOME/Library/Android/sdk/emulator/emulator -list-avds

# Boot the emulator (runs in background)
$HOME/Library/Android/sdk/emulator/emulator -avd Medium_Phone_API_36.1 &

# Wait for the emulator to fully boot
$HOME/Library/Android/sdk/platform-tools/adb wait-for-device
$HOME/Library/Android/sdk/platform-tools/adb shell 'while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 2; done'

# Run the Flutter app on the emulator
flutter pub get
flutter run -d emulator-5554
```

If the NDK build fails with a `source.properties` error, delete the corrupted NDK and let Gradle re-download it:

```bash
rm -rf $HOME/Library/Android/sdk/ndk/28.2.13676358
```
