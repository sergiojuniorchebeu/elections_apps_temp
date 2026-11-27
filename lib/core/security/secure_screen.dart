import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Native side: MainActivity.kt (FLAG_SECURE) and AppDelegate.swift
/// (recording detection). Missing plugin (tests, desktop) = no-op.
abstract final class SecureScreenChannel {
  static const _channel = MethodChannel('civic/secure_screen');
  static int _holders = 0;
  static bool _listening = false;

  /// The screen is being recorded or mirrored (iOS).
  static final captured = ValueNotifier<bool>(false);

  static Future<void> _call(String method) async {
    try {
      await _channel.invokeMethod<void>(method);
    } on MissingPluginException {
      // Tests, desktop.
    } on PlatformException {
      // Never break a screen over this.
    }
  }

  static void _listen() {
    if (_listening) return;
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'capturedChanged') {
        captured.value = call.arguments == true;
      }
    });
    _channel
        .invokeMethod<bool>('isCaptured')
        .then((v) => captured.value = v ?? false)
        .catchError((_) => false);
  }

  static void acquire() {
    _listen();
    if (_holders++ == 0) _call('enable');
  }

  static void release() {
    if (_holders > 0 && --_holders == 0) _call('disable');
  }
}

/// Wrap a sensitive screen or sheet: no screenshots on Android, content
/// hidden while the screen is recorded on iOS.
class SecureScreen extends StatefulWidget {
  const SecureScreen({super.key, required this.child, required this.hidden});

  final Widget child;

  /// Shown instead of [child] while the screen is recorded.
  final Widget hidden;

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  @override
  void initState() {
    super.initState();
    SecureScreenChannel.acquire();
  }

  @override
  void dispose() {
    SecureScreenChannel.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: SecureScreenChannel.captured,
    builder: (_, captured, _) => captured ? widget.hidden : widget.child,
  );
}
