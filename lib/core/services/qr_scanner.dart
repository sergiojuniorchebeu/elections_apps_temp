import 'package:material_ui/material_ui.dart';

/// Camera QR scanner. Default: none (screens fall back on typing the
/// code). Plug `mobile_scanner` by returning its widget here.
abstract interface class QrScanner {
  bool get isAvailable;

  /// Full-screen scanner; calls [onCode] once with the scanned text.
  Widget build(BuildContext context, ValueChanged<String> onCode);
}

final class NoQrScanner implements QrScanner {
  const NoQrScanner();
  @override
  bool get isAvailable => false;
  @override
  Widget build(BuildContext context, ValueChanged<String> onCode) =>
      const SizedBox.shrink();
}
