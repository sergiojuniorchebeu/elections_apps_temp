import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ticks when the app comes back after [threshold] or more in the
/// background. Main screens listen and refresh.
final appResumeProvider = NotifierProvider<AppResume, int>(AppResume.new);

class AppResume extends Notifier<int> {
  static const threshold = Duration(seconds: 30);

  DateTime? _pausedAt;
  DateTime Function() clock = DateTime.now;

  @override
  int build() => 0;

  void paused() => _pausedAt ??= clock();

  void resumed() {
    final at = _pausedAt;
    _pausedAt = null;
    if (at != null && clock().difference(at) >= threshold) state++;
  }
}
