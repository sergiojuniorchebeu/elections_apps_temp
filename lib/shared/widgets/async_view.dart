import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/error/failure.dart';
import 'failure_view.dart';

/// Loading / error / data for an [AsyncValue], with the skeleton of the
/// screen while loading.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    required this.skeleton,
    required this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T) data;
  final Widget skeleton;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (value.hasValue) return data(value.requireValue);
    if (value.hasError) {
      return Center(
        child: SingleChildScrollView(
          child: FailureView(failure: Failure.from(value.error!), onRetry: onRetry),
        ),
      );
    }
    return skeleton;
  }
}
