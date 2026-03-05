class AppConstants {
  // ─── Server URLs ─────────────────────────────────────────────
  // Update this to your server IP when testing on a real device
  static const String baseUrl = 'http://10.0.2.2:3001'; // Android emulator → localhost
  static const String socketUrl = 'http://10.0.2.2:3001';

  // ─── Storage Keys ─────────────────────────────────────────────
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String themeKey = 'is_dark_mode';

  // ─── Pagination ───────────────────────────────────────────────
  static const int messagesPageSize = 50;

  // ─── App Info ─────────────────────────────────────────────────
  static const String appName = 'ChatApp';
}
