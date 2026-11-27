import 'package:material_ui/material_ui.dart';

import '../../core/error/failure.dart';
import '../../design_system/design_system.dart';
import '../../l10n/strings.dart';

/// Full-area error for a [Failure]: title + message + Retry when it may
/// help.
class FailureView extends StatelessWidget {
  const FailureView({super.key, required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  static IconData iconFor(Failure f) => switch (f) {
    NetworkFailure() => Icons.wifi_off_rounded,
    TimeoutFailure() => Icons.hourglass_empty_rounded,
    AuthFailure() => Icons.lock_outline_rounded,
    NotFoundFailure() => Icons.search_off_rounded,
    RateLimitFailure() => Icons.timer_outlined,
    ValidationFailure() || ConflictFailure() => Icons.info_outline_rounded,
    ServerFailure() || UnknownFailure() || CancelledFailure() =>
      Icons.cloud_off_rounded,
  };

  @override
  Widget build(BuildContext context) => StateView(
    icon: iconFor(failure),
    title: failure.title,
    message: failure.requestId == null
        ? failure.message
        : '${failure.message}\nRéférence : ${failure.requestId}',
    actionLabel: failure.retryable || failure is NotFoundFailure ? CommonStrings.retry : null,
    onAction: onRetry,
    tone: StateTone.danger,
  );
}

/// Snack bar for a failure that does not replace the screen (refresh
/// failed, action refused).
void showFailureSnack(BuildContext context, Failure failure) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('${failure.title}. ${failure.message}')));
}

void showInfoSnack(BuildContext context, String message) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
