// Build script: it runs in a terminal where stdout IS the UI, so print is
// intentional here.
// ignore_for_file: avoid_print

import 'dart:io';

void main(final List<String> args) async {
  print('🛠️  Building Lore Console App...');

  // Create a bin directory if it doesn't exist
  final binDir = Directory('bin');
  if (!binDir.existsSync()) {
    binDir.createSync();
  }

  // Compile the console executable
  print('Compiling executable...');
  final result = await Process.run('dart', [
    'compile',
    'exe',
    'lib/console_main.dart',
    '-o',
    'bin/lore',
  ]);

  if (result.exitCode != 0) {
    print('❌ Build failed:');
    print(result.stderr);
    exit(1);
  }

  // Make the file executable
  if (Platform.isLinux || Platform.isMacOS) {
    await Process.run('chmod', ['+x', 'bin/lore']);
  }

  print('✅ Lore console app built successfully!');
  print('📁 Executable located at: ${Directory.current.path}/bin/lore');
}
