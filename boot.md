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

