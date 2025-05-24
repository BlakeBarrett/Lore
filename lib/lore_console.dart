import 'dart:io';

import 'package:Lore/artifact.dart';
import 'package:Lore/lore_api.dart';
import 'package:Lore/md5_utils.dart';
import 'package:Lore/supabase_service.dart';
import 'package:regexpattern/regexpattern.dart';

class LoreConsole {
  final List<String> args;

  LoreConsole._(this.args);

  static Future<LoreConsole> create(List<String> args) async {
    final console = LoreConsole._(args);
    await console._initialize();
    return console;
  }

  Future<void> _initialize() async {
    await SupabaseService.instance.initializeForConsole();
    await _handleArgs();
  }

  Future<void> _handleArgs() async {
    if (args.isEmpty) {
      _printUsage();
      await _cleanup();
      exit(0);
    }

    final String command = args[0].toLowerCase();

    try {
      switch (command) {
        case 'help':
          _printUsage();
          await _cleanup();
          exit(0);
        case 'get':
          if (args.length < 2) {
            stdout.writeln('Error: Missing artifact identifier');
            _printCommandUsage('get');
            await _cleanup();
            exit(1);
          }
          await _getArtifact(args[1]);
          break;
        case 'add-remark':
          if (args.length < 3) {
            stdout.writeln('Error: Missing md5sum or remark text');
            _printCommandUsage('add-remark');
            await _cleanup();
            exit(1);
          }
          await _addRemark(args[1], args.sublist(2).join(' '));
          break;
        case 'login':
          if (args.length < 2) {
            stdout.writeln('Error: Missing JWT token');
            _printCommandUsage('login');
            await _cleanup();
            exit(1);
          }
          await _login(args[1]);
          break;
        case 'list-favorites':
          await _listFavorites();
          break;
        case 'print-remarks':
          if (args.length < 2) {
            stdout.writeln('Error: Missing file path or md5 hash');
            stdout.writeln('Usage: lore <file> or lore -md5=<hash>');
            await _cleanup();
            exit(1);
          }
          await _printRemarks(args[1]);
          break;
        default:
          // NEW REQUIREMENT: Default behavior for file paths
          if (args.length == 1) {
            // Treat the single argument as a file path and show remarks
            await _printRemarks(args[0]);
          } else {
            stdout.writeln('Unknown command: $command');
            _printUsage();
            await _cleanup();
            exit(1);
          }
      }
    } catch (e) {
      stdout.writeln('Error executing command: $e');
      await _cleanup();
      exit(1);
    }

    // Ensure the app exits after command completion
    await _cleanup();
    exit(0);
  }

  Future<void> _cleanup() async {
    try {
      await SupabaseService.instance.dispose();
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  Future<void> _getArtifact(String identifier) async {
    stdout.writeln('Fetching artifact: $identifier');

    Artifact artifact;
    if (identifier.isMD5()) {
      artifact = await LoreAPI.loadArtifact(identifier) ??
          Artifact(path: '', md5sum: identifier);
    } else {
      final md5sum = md5SumFor(identifier);
      stdout.writeln('Calculated MD5: $md5sum');
      artifact = await LoreAPI.loadArtifact(md5sum) ??
          Artifact(path: '', md5sum: md5sum);
    }

    stdout.writeln('Artifact: ${artifact.path} (${artifact.md5sum})');

    if (artifact.remarks != null && artifact.remarks!.isNotEmpty) {
      stdout.writeln('\nRemarks:');
      for (final remark in artifact.remarks!) {
        stdout.writeln('- ${remark.text} (by: ${remark.author})');
      }
    } else {
      stdout.writeln('\nNo remarks found.');
    }
  }

  Future<void> _addRemark(String md5sum, String remarkText) async {
    if (LoreAPI.userId == null) {
      stdout.writeln('Error: You must be logged in to add remarks.');
      await _cleanup();
      exit(1);
    }

    stdout.writeln('Adding remark to artifact $md5sum: "$remarkText"');

    try {
      await LoreAPI.saveRemark(
          remark: remarkText, md5sum: md5sum, userId: LoreAPI.userId);
      stdout.writeln('Remark added successfully!');
    } catch (e) {
      stdout.writeln('Failed to add remark: $e');
      await _cleanup();
      exit(1);
    }
  }

  Future<void> _login(String jwt) async {
    stdout.writeln('Attempting to log in with provided JWT...');

    try {
      final response =
          await SupabaseService.instance.client.auth.recoverSession(jwt);
      stdout.writeln('Login successful!');
      stdout.writeln('User: ${response.user?.email ?? "Unknown"}');
    } catch (e) {
      stdout.writeln('Login failed: $e');
      await _cleanup();
      exit(1);
    }
  }

  Future<void> _listFavorites() async {
    if (LoreAPI.userId == null) {
      stdout.writeln('Error: You must be logged in to list favorites.');
      await _cleanup();
      exit(1);
    }

    stdout.writeln('Fetching your favorite artifacts...');

    try {
      final favorites =
          await LoreAPI.loadFavoritesArtifacts(userId: LoreAPI.userId);

      if (favorites.isEmpty) {
        stdout.writeln('You have no favorite artifacts.');
        return;
      }

      stdout.writeln('\nYour favorites:');
      for (final artifact in favorites) {
        stdout.writeln('- ${artifact.path} (${artifact.md5sum})');
      }
    } catch (e) {
      stdout.writeln('Failed to fetch favorites: $e');
      await _cleanup();
      exit(1);
    }
  }

  Future<void> _printRemarks(String identifier) async {
    String md5sum;
    if (identifier.isMD5()) {
      md5sum = identifier;
    } else {
      final file = File(identifier);
      if (!file.existsSync()) {
        stdout.writeln('File not found: $identifier');
        await _cleanup();
        exit(1);
      }
      md5sum = await calculateMD5(file.openRead());
    }
    final remarks = await LoreAPI.loadRemarks(md5sum: md5sum);
    if (remarks.isEmpty) {
      stdout.writeln('No remarks found for $identifier');
      return;
    }
    stdout.writeln(
        'Top ${remarks.length > 50 ? 50 : remarks.length} remarks for $identifier:');
    for (final remark in remarks.take(50)) {
      stdout
          .writeln('- [${remark.timestamp}] ${remark.author}: ${remark.text}');
    }
  }

  void _printUsage() {
    stdout.writeln('Lore - The shared, single source of truth for everything.');
    stdout.writeln('\nUsage:');
    stdout.writeln('  lore <command> [arguments]');
    stdout
        .writeln('  lore <file_path>                Show remarks for a file\n');
    stdout.writeln('Available commands:');
    stdout.writeln('  help                   Show this help message');
    stdout.writeln('  get <md5|text>         Get artifact by MD5 hash or text');
    stdout.writeln('  add-remark <md5> <text>  Add a remark to an artifact');
    stdout.writeln('  login <jwt>            Login with a JWT token');
    stdout.writeln('  list-favorites         List your favorite artifacts');
    stdout.writeln(
        '  print-remarks <file|md5>  Print top remarks for a file or hash');
    stdout.writeln('\nExamples:');
    stdout.writeln('  lore ./README.md       Show remarks for README.md');
    stdout.writeln('  lore help              Show this help message');
    stdout.writeln('  lore get abc123        Get artifact by MD5 hash');
  }

  void _printCommandUsage(String command) {
    switch (command) {
      case 'get':
        stdout.writeln('Usage: lore get <md5|text>');
        stdout.writeln(
            '  Retrieves an artifact and its remarks by MD5 hash or text content.');

      case 'add-remark':
        stdout.writeln('Usage: lore add-remark <md5> <text>');
        stdout.writeln(
            '  Adds a new remark to the artifact with the specified MD5 hash.');

      case 'login':
        stdout.writeln('Usage: lore login <jwt>');
        stdout.writeln('  Authenticates using a JWT token from Supabase.');

      case 'print-remarks':
        stdout.writeln('Usage: lore print-remarks <file|md5>');
        stdout.writeln(
            '  Prints the top remarks for the specified file or MD5 hash.');
    }
  }
}
