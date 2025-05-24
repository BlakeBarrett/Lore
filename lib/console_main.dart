import 'dart:io';

import 'package:Lore/lore_console.dart';

void main(List<String> args) async {
  // Handle console commands
  await LoreConsole.create(args);
}
