import 'package:hive_flutter/hive_flutter.dart';

import 'local_db.dart';

class AppPreferences {
  static Box get _box => LocalDb.preferencesBox;

  static const String _onboardingSeenKey = 'onboarding_seen';

  static bool get hasSeenOnboarding =>
      _box.get(_onboardingSeenKey, defaultValue: false) as bool;

  static Future<void> setOnboardingSeen() async {
    await _box.put(_onboardingSeenKey, true);
  }
}
