import 'dart:io';

import 'package:Lore/lore_app.dart';
import 'package:desktop_window/desktop_window.dart' as window_size;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main(final List<String> args) async {
  debugPrint('main(args[]) = $args');
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: 'supabase.env');
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );

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
  runApp(const LoreApp());
}

final SupabaseClient supabaseInstance = Supabase.instance.client;
late final bool kIsDesktop;
