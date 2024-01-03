import 'dart:io';

import 'package:Lore/lore_app.dart';
import 'package:desktop_window/desktop_window.dart' as window_size;
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Platform.isWindows ||
        Platform.isLinux ||
        Platform.isFuchsia ||
        Platform.isMacOS) {
      window_size.DesktopWindow.setWindowSize(const Size(600, 1000));
    }
  } catch (e) {
    print(e);
  }
  runApp(const LoreApp());
}
