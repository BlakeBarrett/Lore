import 'dart:io';

import 'package:Lore/lore_app.dart';
import 'package:Lore/lore_console.dart';
import 'package:desktop_window/desktop_window.dart' as window_size;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

late final bool kIsDesktop;
final SupabaseClient supabaseInstance = Supabase.instance.client;

Future<void> initializeSupabase() async {
  await dotenv.load(fileName: 'supabase.env');
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );
}

void main(final List<String> args) async {
  debugPrint('main(args[]) = $args');
  
  // Preserve splash screen while Flutter is initializing
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  await initializeSupabase();
  try {
    if (Platform.isWindows ||
        Platform.isLinux ||
        Platform.isFuchsia ||
        Platform.isMacOS) {
      kIsDesktop = true;
      window_size.DesktopWindow.setWindowSize(const Size(800, 1000));
    } else {
      kIsDesktop = false;
    }
  } catch (e) {
    kIsDesktop = false;
    debugPrint('$e');
  }

  if (args.isEmpty) {
    runApp(const LoreApp());
  } else {
    LoreConsole(args);
  }
}
