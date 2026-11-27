import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core_providers.dart';
import 'preferences.dart';

/// One notifier per setting, persisted under its [PrefKeys] key.
final themeModeProvider = NotifierProvider<ThemeModeSetting, ThemeMode>(
  ThemeModeSetting.new,
);

class ThemeModeSetting extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final raw = ref.read(preferencesProvider).getString(PrefKeys.themeMode);
    return ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(preferencesProvider).setString(PrefKeys.themeMode, mode.name);
  }
}

final analyticsEnabledProvider = NotifierProvider<BoolSetting, bool>(
  () => BoolSetting(PrefKeys.analyticsEnabled, defaultValue: true),
);

final pushEnabledProvider = NotifierProvider<BoolSetting, bool>(
  () => BoolSetting(PrefKeys.pushEnabled, defaultValue: true),
);

class BoolSetting extends Notifier<bool> {
  BoolSetting(this.key, {required this.defaultValue});
  final String key;
  final bool defaultValue;

  @override
  bool build() => ref.read(preferencesProvider).getBool(key) ?? defaultValue;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(preferencesProvider).setBool(key, value);
  }
}
