/// Which implementation answers the repositories. Add a value here when
/// you add your own (see docs/BACKEND.md).
enum BackendKind {
  /// Built-in simulator: realistic data, latency, scenarios. Default.
  mock,

  /// Reference REST implementation (docs/api_contract.yaml).
  rest;

  static BackendKind parse(String raw) => switch (raw.trim().toLowerCase()) {
    'rest' => BackendKind.rest,
    _ => BackendKind.mock,
  };
}

/// Everything the build can change without touching code, read once from
/// `--dart-define` (or `--dart-define-from-file=config/dev.json`).
///
/// Kept immutable and passed through a provider so tests build their own.
final class AppConfig {
  const AppConfig({
    this.backend = BackendKind.mock,
    this.apiBaseUrl = '',
    this.supportEmail = 'support@example.org',
    this.appName = 'Votaa',
    this.mockLatencyMin = const Duration(milliseconds: 300),
    this.mockLatencyMax = const Duration(milliseconds: 800),
    this.showDevPanel = true,
  });

  factory AppConfig.fromEnvironment() {
    const backend = String.fromEnvironment('BACKEND', defaultValue: 'mock');
    const url = String.fromEnvironment('API_BASE_URL');
    const email = String.fromEnvironment(
      'SUPPORT_EMAIL',
      defaultValue: 'support@example.org',
    );
    const name = String.fromEnvironment('APP_NAME', defaultValue: 'Votaa');
    const latency = int.fromEnvironment('MOCK_LATENCY_MS', defaultValue: -1);
    final config = AppConfig(
      backend: BackendKind.parse(backend),
      apiBaseUrl: url,
      supportEmail: email,
      appName: name,
      mockLatencyMin: latency >= 0
          ? Duration(milliseconds: latency)
          : const Duration(milliseconds: 300),
      mockLatencyMax: latency >= 0
          ? Duration(milliseconds: latency)
          : const Duration(milliseconds: 800),
    );
    config.validate();
    return config;
  }

  final BackendKind backend;

  /// Shown in Profile and attached to problem reports.
  static const version = String.fromEnvironment('APP_VERSION', defaultValue: '0.2.0');

  /// Base URL of the REST implementation, e.g. `https://api.example.org/v1`.
  final String apiBaseUrl;
  final String supportEmail;
  final String appName;
  final Duration mockLatencyMin;
  final Duration mockLatencyMax;

  /// The scenario panel (only ever shown in demo mode).
  final bool showDevPanel;

  /// Demo mode = running on the simulator: demo accounts shown on the
  /// sign-in screen, scenario panel available.
  bool get isDemo => backend == BackendKind.mock;

  /// HTTPS is mandatory for any network implementation, except localhost
  /// during development.
  void validate() {
    if (backend == BackendKind.mock) return;
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError(
        'API_BASE_URL is missing or invalid for BACKEND=${backend.name}. '
        'Example: --dart-define=API_BASE_URL=https://api.example.org/v1',
      );
    }
    if (!isAllowedUrl(uri)) {
      throw StateError('API_BASE_URL must use https:// (got $apiBaseUrl).');
    }
  }

  static bool isAllowedUrl(Uri uri) {
    const local = {'localhost', '127.0.0.1', '10.0.2.2'};
    return uri.scheme == 'https' ||
        (uri.scheme == 'http' && local.contains(uri.host));
  }

  AppConfig copyWith({BackendKind? backend, String? apiBaseUrl}) => AppConfig(
    backend: backend ?? this.backend,
    apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
    supportEmail: supportEmail,
    appName: appName,
    mockLatencyMin: mockLatencyMin,
    mockLatencyMax: mockLatencyMax,
    showDevPanel: showDevPanel,
  );
}
