import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The conventional newborn programmer greeting
  ///
  /// In en, this message translates to:
  /// **'Hello World!'**
  String get helloWorld;

  /// Text for browse file button
  ///
  /// In en, this message translates to:
  /// **'Browse for file'**
  String get browseForFile;

  /// Hint text for search bar
  ///
  /// In en, this message translates to:
  /// **'Search by MD5 or URL'**
  String get searchByMd5OrURL;

  /// Button label for adding to favorites
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// Button label for removing from favorites
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// Hint text for adding a remark
  ///
  /// In en, this message translates to:
  /// **'Add a remark'**
  String get addRemark;

  /// Text for delete button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Text for logout button
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Label for author field
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @timeStamp.
  ///
  /// In en, this message translates to:
  /// **'Time Stamp'**
  String get timeStamp;

  /// The application title
  ///
  /// In en, this message translates to:
  /// **'Lore'**
  String get appTitle;

  /// Button label for the authenticate button
  ///
  /// In en, this message translates to:
  /// **'Authenticate'**
  String get authenticate;

  /// Prompt asking for the e-mail address to send the one time password
  ///
  /// In en, this message translates to:
  /// **'To which e-mail address should we send a one time password?'**
  String get emailPrompt;

  /// Label for the e-mail address field
  ///
  /// In en, this message translates to:
  /// **'e-mail address'**
  String get emailAddress;

  /// Prompt asking for the one time password that was sent
  ///
  /// In en, this message translates to:
  /// **'Now enter the one-time-password we sent.'**
  String get otpPrompt;

  /// Label for the one time password field
  ///
  /// In en, this message translates to:
  /// **'One Time Password...'**
  String get oneTimePassword;

  /// Attribution label for avatars provided by Gravatar
  ///
  /// In en, this message translates to:
  /// **'Avatars by Gravatar'**
  String get avatarsByGravatar;

  /// Note indicating Lore is open source on GitHub
  ///
  /// In en, this message translates to:
  /// **'Lore is Open Source, available on GitHub.'**
  String get openSourceNote;

  /// Copyright notice shown in the drawer footer
  ///
  /// In en, this message translates to:
  /// **'Lore (c) 2024 Blake Barrett.'**
  String get copyright;

  /// Tooltip text for the add remark control
  ///
  /// In en, this message translates to:
  /// **'Add a remark...'**
  String get addRemarkTooltip;

  /// Prompt shown when the user must login before adding a remark
  ///
  /// In en, this message translates to:
  /// **'Login to add a remark.\nClick to login.'**
  String get loginPrompt;

  /// Label for the sign in control
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Error message shown when loading fails
  ///
  /// In en, this message translates to:
  /// **'Could not load.'**
  String get errorLoading;

  /// Error message shown when saving fails
  ///
  /// In en, this message translates to:
  /// **'Could not save. Please try again.'**
  String get errorSaving;

  /// Error message shown when deleting fails
  ///
  /// In en, this message translates to:
  /// **'Could not delete.'**
  String get errorDeleting;

  /// Message shown when an artifact has no remarks
  ///
  /// In en, this message translates to:
  /// **'No remarks yet.'**
  String get noRemarksYet;

  /// Message shown when the favorites list is empty
  ///
  /// In en, this message translates to:
  /// **'No favorite artifacts yet.'**
  String get noFavoritesYet;

  /// Tooltip for the delete menu button
  ///
  /// In en, this message translates to:
  /// **'Delete remark'**
  String get deleteMenu;

  /// Accessibility label prefix for the remark author
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get authorLabel;

  /// Loading indicator text while an artifact is being processed
  ///
  /// In en, this message translates to:
  /// **'Working...'**
  String get loadingArtifact;

  /// Error message shown when sign-in or the auth stream fails
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please try again.'**
  String get errorAuth;

  /// Accessibility label for the artifact image preview
  ///
  /// In en, this message translates to:
  /// **'{name} preview'**
  String imagePreviewLabel(String name);

  /// No description provided for @onboardingFirst.
  ///
  /// In en, this message translates to:
  /// **'First!'**
  String get onboardingFirst;

  /// No description provided for @onboardingHowDidIGetHere.
  ///
  /// In en, this message translates to:
  /// **'How did I get here?'**
  String get onboardingHowDidIGetHere;

  /// No description provided for @onboardingHowDoesItWork.
  ///
  /// In en, this message translates to:
  /// **'This is cool, how does it work?'**
  String get onboardingHowDoesItWork;

  /// Onboarding remark explaining drag-and-drop
  ///
  /// In en, this message translates to:
  /// **'Drop a file from anywhere on your computer into this window to start the conversation around it.'**
  String get onboardingDropHint;

  /// No description provided for @onboardingWhatHappensToFile.
  ///
  /// In en, this message translates to:
  /// **'What happens to my file?'**
  String get onboardingWhatHappensToFile;

  /// No description provided for @onboardingFileStaysLocal.
  ///
  /// In en, this message translates to:
  /// **'Your file stays on your computer.'**
  String get onboardingFileStaysLocal;

  /// No description provided for @onboardingHashExplainer.
  ///
  /// In en, this message translates to:
  /// **'A hash is generated and used as a stand in for the file. That\'s what the \"md5\" field is.'**
  String get onboardingHashExplainer;

  /// No description provided for @onboardingSeeYouInTheComments.
  ///
  /// In en, this message translates to:
  /// **'Cool! I\'ll see you in the comments.'**
  String get onboardingSeeYouInTheComments;

  /// Primary action label that emails the one-time password
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// Primary action label that verifies the entered one-time password
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyCode;

  /// Confirmation shown after a one-time password was sent
  ///
  /// In en, this message translates to:
  /// **'Code sent to {email}'**
  String codeSentTo(String email);

  /// Action to unlock the e-mail field and change the address after a code was sent
  ///
  /// In en, this message translates to:
  /// **'Use a different address?'**
  String get useDifferentEmail;

  /// Inline validation error for a malformed e-mail address
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t look like an e-mail address.'**
  String get errorInvalidEmail;

  /// Accessibility/tooltip label naming the author of a remark
  ///
  /// In en, this message translates to:
  /// **'Author: {author}'**
  String remarkAuthorLabel(String author);

  /// Label shown instead of the account id when the remark author is the signed-in user
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get remarkYou;

  /// Confirmation question before deleting a remark
  ///
  /// In en, this message translates to:
  /// **'Delete this remark?'**
  String get deleteRemarkConfirm;

  /// Cancel action label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
