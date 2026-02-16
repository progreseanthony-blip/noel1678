import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get supabaseUrl => dotenv.get('SUPABASE_URL');
  static String get supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY');
  static String get environment => dotenv.get('ENVIRONMENT', fallback: 'development');

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';

  static Future<void> initialize() async {
    const env = String.fromEnvironment('ENVIRONMENT', defaultValue: 'production');
    final fileName = env == 'development' ? '.env.development' : '.env.production';
    await dotenv.load(fileName: fileName);
  }
}
