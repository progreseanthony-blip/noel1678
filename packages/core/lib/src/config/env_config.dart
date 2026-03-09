
class EnvConfig {
  static const String supabaseUrl = 'http://127.0.0.1:54421';
  static const String supabaseAnonKey = 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';
  static const String environment = 'development';

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';

  static Future<void> initialize() async {
    // No initialization needed for const String.fromEnvironment
  }
}
