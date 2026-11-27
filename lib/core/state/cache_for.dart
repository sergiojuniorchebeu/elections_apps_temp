import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

extension CacheFor on Ref {
  /// Keeps an `autoDispose` provider alive for [duration] after its last
  /// listener left: reopening a detail right after closing it is instant.
  void cacheFor(Duration duration) {
    final link = keepAlive();
    Timer? timer;
    onCancel(() => timer = Timer(duration, link.close));
    onResume(() => timer?.cancel());
    onDispose(() => timer?.cancel());
  }
}
