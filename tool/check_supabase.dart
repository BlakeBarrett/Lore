#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print('🔍 Checking Supabase configuration...\n');

  // Load environment variables
  final envFile = File('supabase.env');
  if (!envFile.existsSync()) {
    print('❌ supabase.env file not found');
    exit(1);
  }

  final envContent = await envFile.readAsString();
  final lines = envContent.split('\n');
  String? supabaseUrl;
  String? anonKey;

  for (final line in lines) {
    if (line.startsWith('SUPABASE_URL=')) {
      supabaseUrl = line.split('=')[1].replaceAll("'", "").replaceAll('"', '');
    } else if (line.startsWith('SUPABASE_ANON_KEY=')) {
      anonKey = line.split('=')[1].replaceAll("'", "").replaceAll('"', '');
    }
  }

  if (supabaseUrl == null || anonKey == null) {
    print('❌ Missing SUPABASE_URL or SUPABASE_ANON_KEY in supabase.env');
    exit(1);
  }

  print('📍 Supabase URL: $supabaseUrl');
  print('🔑 Anon Key: ${anonKey.substring(0, 20)}...\n');

  // Test URL accessibility
  print('🌐 Testing URL accessibility...');
  try {
    final response = await http.get(
      Uri.parse('$supabaseUrl/rest/v1/'),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
      },
    ).timeout(Duration(seconds: 10));

    if (response.statusCode == 200) {
      print('✅ Supabase URL is accessible');
      print('📊 Response: ${response.body}');
    } else {
      print(
          '⚠️  Supabase URL accessible but returned status: ${response.statusCode}');
      print('📊 Response: ${response.body}');
    }
  } catch (e) {
    print('❌ Supabase URL is not accessible: $e');
    print('');
    print('🔧 This usually means:');
    print('   1. The Supabase project was deleted or renamed');
    print('   2. The URL in supabase.env is incorrect');
    print('   3. You need to create a new Supabase project');
    print('');
    print('📝 To fix this:');
    print('   1. Go to https://supabase.com/dashboard');
    print('   2. Create a new project or find your existing one');
    print('   3. Update supabase.env with the correct URL and keys');
    print('   4. Update any hardcoded URLs in the codebase');
  }
}
