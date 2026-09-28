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
  String get removeFromFavorites => 'Remove from favorites';

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
  String get deleteMenu => 'Delete remark';

  @override
  String get authorLabel => 'Author';

  @override
  String get loadingArtifact => 'Working...';

  @override
  String get errorAuth => 'Authentication failed. Please try again.';

  @override
  String imagePreviewLabel(String name) {
    return '$name preview';
  }

  @override
  String get onboardingFirst => 'First!';

  @override
  String get onboardingHowDidIGetHere => 'How did I get here?';

  @override
  String get onboardingHowDoesItWork => 'This is cool, how does it work?';

  @override
  String get onboardingDropHint =>
      'Drop a file from anywhere on your computer into this window to start the conversation around it.';

  @override
  String get onboardingWhatHappensToFile => 'What happens to my file?';

  @override
  String get onboardingFileStaysLocal => 'Your file stays on your computer.';

  @override
  String get onboardingHashExplainer =>
      'A hash is generated and used as a stand in for the file. That\'s what the \"md5\" field is.';

  @override
  String get onboardingSeeYouInTheComments =>
      'Cool! I\'ll see you in the comments.';

  @override
  String get sendCode => 'Send code';

  @override
  String get verifyCode => 'Verify';

  @override
  String codeSentTo(String email) {
    return 'Code sent to $email';
  }

  @override
  String get useDifferentEmail => 'Use a different address?';

  @override
  String get errorInvalidEmail => 'That doesn\'t look like an e-mail address.';

  @override
  String remarkAuthorLabel(String author) {
    return 'Author: $author';
  }

  @override
  String get remarkYou => 'You';

  @override
  String get deleteRemarkConfirm => 'Delete this remark?';

  @override
  String get cancel => 'Cancel';
}
