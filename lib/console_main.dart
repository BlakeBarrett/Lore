import 'dart:io';

import 'package:Lore/lore_console.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final SupabaseClient supabaseInstance = Supabase.instance.client;

Future<void> initializeSupabase() async {
  await dotenv.load(fileName: 'supabase.env');
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );
}

void main(List<String> args) async {
  // Initialize Supabase
  await initializeSupabase();

  // Handle console commands
  LoreConsole(args);
}
