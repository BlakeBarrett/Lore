import 'package:Lore/app_config.dart';
import 'package:Lore/lore_console.dart';

Future<void> main(final List<String> args) async {
  await AppConfig.init(desktop: true);

  // Handle console commands
  LoreConsole.bindDefaults(AppConfig.instance);
  await LoreConsole(args).done;
}
