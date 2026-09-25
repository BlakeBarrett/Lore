import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Single source of truth for app-wide configuration: the Supabase client
/// and platform flags. Replaces the scattered `supabaseInstance` globals and
/// duplicated `initializeSupabase()` bootstrap in `main.dart` /
/// `console_main.dart`.
class AppConfig {
  final SupabaseClient supabase;
  final bool isDesktop;
  final bool isWeb;

  AppConfig._({
    required this.supabase,
    required this.isDesktop,
    required this.isWeb,
  });

  static late final AppConfig instance;

  static Future<void> init({bool desktop = false}) async {
    await dotenv.load(fileName: 'supabase.env');
    await Supabase.initialize(
      url: dotenv.get('SUPABASE_URL'),
      publishableKey: dotenv.get('SUPABASE_ANON_KEY'),
    );
    instance = AppConfig._(
      supabase: Supabase.instance.client,
      isDesktop: desktop,
      isWeb: kIsWeb,
    );
  }
}
