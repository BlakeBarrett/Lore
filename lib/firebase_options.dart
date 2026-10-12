/// Stub firebase_options.dart for development.
/// Run `flutterfire configure` to generate a real version with platform-specific configs.
library;

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'STUB_API_KEY',
      appId: '1:000000000000:web:stub',
      messagingSenderId: '000000000000',
      projectId: 'stub-project-id',
    );
  }

  static FirebaseOptions get web => _web;
}

FirebaseOptions get _web {
  return const FirebaseOptions(
    apiKey: 'STUB_API_KEY',
    appId: '1:000000000000:web:stub',
    messagingSenderId: '000000000000',
    projectId: 'stub-project-id',
  );
}
