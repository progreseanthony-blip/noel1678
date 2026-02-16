
class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';

  static Future<void> initialize() async {
    // No initialization needed for const String.fromEnvironment
  }
}
