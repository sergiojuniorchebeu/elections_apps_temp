import 'package:shared_preferences/shared_preferences.dart';

/// Every preference key, in one place: nothing else spells a key.
abstract final class PrefKeys {
  /// Present once the app has run on this install (iOS keeps the Keychain
  /// after uninstall: its absence means "wipe secure storage").
  static const installMarker = 'install.marker';
  static const deviceId = 'device.id';
  static const themeMode = 'ui.theme_mode';
  static const analyticsEnabled = 'privacy.analytics_enabled';
  static const appLockEnabled = 'security.app_lock';
  static const pushEnabled = 'notifications.push_enabled';
  static const onboardingSeen = 'onboarding.seen';

  /// Preferences tied to the signed-in account, cleared on sign-out.
  static const accountScoped = {appLockEnabled, pushEnabled};
}

/// Small synchronous key/value store for simple settings. An interface so
/// tests use [MemoryPreferences] and nobody depends on the plugin.
abstract interface class Preferences {
  String? getString(String key);
  bool? getBool(String key);
  Future<void> setString(String key, String value);
  Future<void> setBool(String key, bool value);
  Future<void> remove(String key);
}

final class SharedPrefs implements Preferences {
  SharedPrefs(this._prefs);

  static Future<SharedPrefs> load() async =>
      SharedPrefs(await SharedPreferencesWithCache.create(
        cacheOptions: const SharedPreferencesWithCacheOptions(),
      ));

  final SharedPreferencesWithCache _prefs;

  @override
  String? getString(String key) => _prefs.getString(key);
  @override
  bool? getBool(String key) => _prefs.getBool(key);
  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);
  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

final class MemoryPreferences implements Preferences {
  MemoryPreferences([Map<String, Object>? values]) : values = {...?values};

  final Map<String, Object> values;

  @override
  String? getString(String key) => values[key] as String?;
  @override
  bool? getBool(String key) => values[key] as bool?;
  @override
  Future<void> setString(String key, String value) async =>
      values[key] = value;
  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;
  @override
  Future<void> remove(String key) async => values.remove(key);
}
