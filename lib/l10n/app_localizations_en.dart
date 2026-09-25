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

  @override
  String get authenticate => 'Authenticate';

  @override
  String get emailPrompt =>
      'To which e-mail address should we send a one time password?';

  @override
  String get emailAddress => 'e-mail address';

  @override
  String get otpPrompt => 'Now enter the one-time-password we sent.';

  @override
  String get oneTimePassword => 'One Time Password...';

  @override
  String get avatarsByGravatar => 'Avatars by Gravatar';

  @override
  String get openSourceNote => 'Lore is Open Source, available on GitHub.';

  @override
  String get copyright => 'Lore (c) 2024 Blake Barrett.';

  @override
  String get addRemarkTooltip => 'Add a remark...';

  @override
  String get loginPrompt => 'Login to add a remark.\nClick to login.';

  @override
  String get signIn => 'Sign in';

  @override
  String get errorLoading => 'Could not load.';

  @override
  String get errorSaving => 'Could not save. Please try again.';

  @override
  String get errorDeleting => 'Could not delete.';

  @override
  String get noRemarksYet => 'No remarks yet.';

  @override
  String get noFavoritesYet => 'No favorite artifacts yet.';

  @override
  String get searchLabel => 'Search by MD5 or URL';

  @override
  String get favoriteLabel => 'Add to favorites';

  @override
  String get deleteMenu => 'Delete remark';

  @override
  String get authorLabel => 'Author';

  @override
  String get loadingArtifact => 'Working...';
}
