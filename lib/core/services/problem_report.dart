import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/strings.dart';

/// What the user sends with "Report a problem". No personal data is added
/// automatically: only app version, platform and the last request id.
final class ProblemReport {
  const ProblemReport({
    required this.description,
    required this.appVersion,
    required this.platform,
    this.requestId,
  });

  final String description;
  final String appVersion;
  final String platform;
  final String? requestId;

  String get body =>
      '$description\n\n---\nApp: $appVersion\nPlatform: $platform'
      '${requestId == null ? '' : '\nRequest: $requestId'}';
}

abstract interface class ProblemReporter {
  /// Returns false when the report could not be handed over.
  Future<bool> send(ProblemReport report);
}

/// Default: opens the mail app with a prefilled message.
final class EmailProblemReporter implements ProblemReporter {
  const EmailProblemReporter(this.to);
  final String to;

  @override
  Future<bool> send(ProblemReport report) async {
    final uri = Uri(
      scheme: 'mailto',
      path: to,
      query: _encode({'subject': ProfileStrings.reportSubject, 'body': report.body}),
    );
    try {
      return await launchUrl(uri);
    } on Object {
      return false;
    }
  }

  static String _encode(Map<String, String> params) => params.entries
      .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
      .join('&');
}

/// Example: `POST {endpoint}` with `{description, app_version, platform,
/// request_id}`.
final class ApiProblemReporter implements ProblemReporter {
  ApiProblemReporter(this.endpoint, [Dio? dio]) : _dio = dio ?? Dio();
  final Uri endpoint;
  final Dio _dio;

  @override
  Future<bool> send(ProblemReport report) async {
    try {
      await _dio.postUri<void>(endpoint, data: {
        'description': report.description,
        'app_version': report.appVersion,
        'platform': report.platform,
        'request_id': report.requestId,
      });
      return true;
    } on Object {
      return false;
    }
  }
}
