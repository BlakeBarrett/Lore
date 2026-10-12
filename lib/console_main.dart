import 'dart:io';

import 'package:lore/lore_console.dart';
import 'package:lore/repo/firestore_rest_repo.dart';

/// Standalone Lore CLI (`bin/lore`, built by tool/build_console.dart with
/// `dart compile exe`).
///
/// This entry point — and everything it imports — must stay free of
/// `package:flutter`: the standalone Dart VM cannot embed it, and the
/// federated Firebase SDK plugins (auth/firestore) additionally ship no
/// Linux implementation. Backend access therefore goes through the
/// Firestore/Identity-Toolkit REST APIs (see RestLoreRepo).
///
/// Configuration (environment):
///   FIREBASE_PROJECT_ID    required — the Firebase project id
///   FIREBASE_WEB_API_KEY   required for `lore login` only (Identity Toolkit)
///
/// Sign-in persists to ~/.config/lore/cli-session.json (0600).
Future<void> main(final List<String> args) async {
  final projectId = Platform.environment['FIREBASE_PROJECT_ID'] ?? '';
  final isHelp = args.isEmpty || args.first.toLowerCase() == 'help';
  if (projectId.isEmpty && !isHelp) {
    stderr.writeln('lore: FIREBASE_PROJECT_ID is not set.');
    stderr.writeln('    export FIREBASE_PROJECT_ID=<your-firebase-project-id>'
        '   (the projectId from lib/firebase_options.dart)');
    exit(2);
  }
  LoreConsole.api = RestLoreRepo(
    projectId: projectId,
    apiKey: Platform.environment['FIREBASE_WEB_API_KEY'],
  );
  await LoreConsole(args).done;
}
