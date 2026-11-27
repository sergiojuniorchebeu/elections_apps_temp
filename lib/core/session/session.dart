/// Tokens of the signed-in user. Pure Dart, back-end agnostic: an
/// implementation that has no refresh token (Firebase...) stores its own
/// identifiers in [accessToken] / [refreshToken] as it sees fit.
final class Session {
  const Session({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  factory Session.fromJson(Map<String, Object?> json) => Session(
    userId: json['user_id']! as String,
    accessToken: json['access_token']! as String,
    refreshToken: json['refresh_token']! as String,
    expiresAt: DateTime.parse(json['expires_at']! as String),
  );

  final String userId;
  final String accessToken;
  final String refreshToken;

  /// When [accessToken] stops being accepted.
  final DateTime expiresAt;

  Session copyWithAccess(String accessToken, {DateTime? expiresAt}) => Session(
    userId: userId,
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresAt: expiresAt ?? this.expiresAt,
  );

  bool isExpired([DateTime? now]) =>
      !(now ?? DateTime.now()).isBefore(expiresAt);

  Map<String, Object?> toJson() => {
    'user_id': userId,
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt.toIso8601String(),
  };
}
