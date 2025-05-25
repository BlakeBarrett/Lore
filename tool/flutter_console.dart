import 'dart:io';

/// Flutter Console Integration Tool
/// This tool helps integrate the Lore console app with Flutter development workflow
void main(List<String> args) async {
  if (args.isEmpty) {
    printUsage();
    return;
  }

  final command = args[0].toLowerCase();

  switch (command) {
    case 'devices':
      await listDevices();
      break;
    case 'build':
      await buildConsole();
      break;
    case 'run':
      await runConsole(args.skip(1).toList());
      break;
    case 'install':
      await buildConsole();
      break;
    case 'launch':
      await launchConsole(args.skip(1).toList());
      break;
    default:
      print('Unknown command: $command');
      printUsage();
  }
}

void printUsage() {
  print('Lore Console Flutter Integration');
  print('Usage: dart tool/flutter_console.dart <command> [args]');
  print('');
  print('Commands:');
  print('  devices    List available console targets');
  print('  build      Build the console application');
  print('  run        Build and run console with arguments');
  print('  install    Build the console (alias for build)');
  print('  launch     Launch the console with arguments');
  print('');
  print('Examples:');
  print('  dart tool/flutter_console.dart build');
  print('  dart tool/flutter_console.dart run help');
  print('  dart tool/flutter_console.dart launch ./README.md');
}

Future<void> listDevices() async {
  print('Lore Console Targets:');
  print('• console-app • Lore Console Application • linux • custom');
  print('• console-interactive • Lore Console (Interactive) • linux • custom');
}

Future<void> buildConsole() async {
  print('🛠️  Building Lore Console...');

  final result = await Process.run('dart', ['tool/build_console.dart']);

  if (result.exitCode == 0) {
    print('✅ Console built successfully');
    print('📍 Executable: ./bin/lore');
  } else {
    print('❌ Build failed');
    print(result.stderr);
    exit(1);
  }
}

Future<void> runConsole(List<String> args) async {
  await buildConsole();
  await launchConsole(args);
}

Future<void> launchConsole(List<String> args) async {
  print('🚀 Launching Lore Console...');

  const executable = './bin/lore';
  if (!File(executable).existsSync()) {
    print('❌ Console executable not found. Run build first.');
    exit(1);
  }

  if (args.isEmpty) {
    print('💡 No arguments provided, showing help:');
    args = ['help'];
  }

  print('Running: $executable ${args.join(' ')}');
  print('─' * 50);

  final result = await Process.run(executable, args);
  print(result.stdout);
  if (result.stderr.isNotEmpty) {
    print('STDERR: ${result.stderr}');
  }

  exit(result.exitCode);
}
