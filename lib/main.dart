import 'dart:io';

import 'package:lore/app_config.dart';
import 'package:lore/lore_app.dart';
import 'package:lore/lore_console.dart';
import 'package:desktop_window/desktop_window.dart' as window_size;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

/// Default desktop window size for the app.
const Size kDefaultWindowSize = Size(800, 1000);

void main(final List<String> args) async {
  debugPrint('main(args[]) = $args');

  // Preserve splash screen while Flutter is initializing.
  // Skipped on web: flutter_native_splash is configured `web: false` in
  // pubspec.yaml, so removeSplashFromWeb() is not injected and the platform
  // channel calls throw PlatformException in the browser.
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

  bool isDesktop = false;
  try {
    isDesktop = Platform.isWindows ||
        Platform.isLinux ||
        Platform.isFuchsia ||
        Platform.isMacOS;
  } catch (e) {
    debugPrint('$e');
  }

  await AppConfig.init(desktop: isDesktop);

  if (args.isEmpty) {
    if (isDesktop) {
      try {
        await window_size.DesktopWindow.setWindowSize(kDefaultWindowSize);
      } catch (e) {
        debugPrint('$e');
      }
    }
    runApp(const LoreApp());
  } else {
    LoreConsole.bindDefaults(AppConfig.instance);
    await LoreConsole(args).done;
  }
}
