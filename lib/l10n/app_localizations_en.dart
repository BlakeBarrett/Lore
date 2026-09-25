// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get helloWorld => 'Hello World!';

  @override
  String get browseForFile => 'Browse for file';

  @override
  String get searchByMd5OrURL => 'Search by MD5 or URL';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get addRemark => 'Add a remark';

  @override
  String get delete => 'Delete';

  @override
  String get logout => 'Logout';

  @override
  String get author => 'Author';

  @override
  String get timeStamp => 'Time Stamp';

  @override
  String get appTitle => 'Lore';
}
