import 'dart:async';

import 'package:elections_app/l10n/strings.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Runs before every test file: same locale and formats as the app.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Intl.defaultLocale = appLocaleTag;
  await initializeDateFormatting(appLocaleTag);
  await testMain();
}
