import 'dart:io';

import 'package:Lore/app_config.dart';
import 'package:Lore/lore_app.dart';
import 'package:Lore/lore_console.dart';
import 'package:desktop_window/desktop_window.dart' as window_size;
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main(final List<String> args) async {
  debugPrint('main(args[]) = $args');

  // Preserve splash screen while Flutter is initializing
  final WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

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
        await window_size.DesktopWindow.setWindowSize(const Size(800, 1000));
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
