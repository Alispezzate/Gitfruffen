import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// Application name shown in the window title and welcome header.
  ///
  /// In en, this message translates to:
  /// **'Gitfruffen'**
  String get appTitle;

  /// Short marketing line under the welcome headline.
  ///
  /// In en, this message translates to:
  /// **'A fast, native Git client for your desktop.'**
  String get welcomeTagline;

  /// Title of the welcome card that opens a local repository.
  ///
  /// In en, this message translates to:
  /// **'Open a repository'**
  String get openRepositoryTitle;

  /// Helper text of the open repository card.
  ///
  /// In en, this message translates to:
  /// **'Select a local folder containing a Git repository.'**
  String get openRepositorySubtitle;

  /// Title passed to the native directory picker and used as tooltip.
  ///
  /// In en, this message translates to:
  /// **'Open repository'**
  String get openRepositoryDialogTitle;

  /// Tooltip of the button that opens a new repository tab.
  ///
  /// In en, this message translates to:
  /// **'Open a repository'**
  String get openRepositoryTooltip;

  /// Button that opens the native folder picker.
  ///
  /// In en, this message translates to:
  /// **'Browse…'**
  String get browseButton;

  /// Button that opens the clone dialog.
  ///
  /// In en, this message translates to:
  /// **'Clone…'**
  String get cloneButton;

  /// Title of the clone dialog.
  ///
  /// In en, this message translates to:
  /// **'Clone repository'**
  String get cloneDialogTitle;

  /// Label of the remote URL field in the clone dialog.
  ///
  /// In en, this message translates to:
  /// **'Remote URL'**
  String get remoteUrlLabel;

  /// Label of the local path field in the clone dialog.
  ///
  /// In en, this message translates to:
  /// **'Local path'**
  String get localPathLabel;

  /// Generic cancel action.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// Confirm action of the clone dialog.
  ///
  /// In en, this message translates to:
  /// **'Clone'**
  String get cloneConfirmButton;

  /// Header of the recent repositories list.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentTitle;

  /// Sidebar destination for the working tree.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get navRepository;

  /// Sidebar destination for the commit log.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navHistory;

  /// Sidebar destination for branches.
  ///
  /// In en, this message translates to:
  /// **'Branches'**
  String get navBranches;

  /// Sidebar destination for settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Placeholder in the sidebar when no repository is open.
  ///
  /// In en, this message translates to:
  /// **'No repository'**
  String get noRepository;

  /// Version label in the sidebar footer.
  ///
  /// In en, this message translates to:
  /// **'Gitfruffen 0.1.0'**
  String get appVersion;

  /// Tooltip of the tab close button.
  ///
  /// In en, this message translates to:
  /// **'Close repository'**
  String get closeRepositoryTooltip;

  /// Label of the button that opens a repository tab.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openButton;

  /// Empty state title when there is no active repository.
  ///
  /// In en, this message translates to:
  /// **'No repository open'**
  String get emptyNoRepository;

  /// Empty state message on the repository page.
  ///
  /// In en, this message translates to:
  /// **'Open a repository from the welcome screen.'**
  String get emptyNoRepositoryMessage;

  /// Loading label while a repository is being opened.
  ///
  /// In en, this message translates to:
  /// **'Opening…'**
  String get openingRepository;

  /// Tooltip of the refresh action.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// Stat chip label for staged changes.
  ///
  /// In en, this message translates to:
  /// **'Staged'**
  String get stagedLabel;

  /// Stat chip label for unstaged changes.
  ///
  /// In en, this message translates to:
  /// **'Unstaged'**
  String get unstagedLabel;

  /// Stat chip label for conflicted files.
  ///
  /// In en, this message translates to:
  /// **'Conflicted'**
  String get conflictedLabel;

  /// Stat chip label for the total number of changes.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// Section title of the working tree changes list.
  ///
  /// In en, this message translates to:
  /// **'Changes'**
  String get changesTitle;

  /// Empty state when there are no changes.
  ///
  /// In en, this message translates to:
  /// **'Working tree clean'**
  String get workingTreeClean;

  /// Subtitle of a renamed file showing its previous path.
  ///
  /// In en, this message translates to:
  /// **'from {path}'**
  String fileChangeFrom(String path);

  /// Badge shown on a staged file.
  ///
  /// In en, this message translates to:
  /// **'staged'**
  String get badgeStaged;

  /// Badge shown on an unstaged file.
  ///
  /// In en, this message translates to:
  /// **'unstaged'**
  String get badgeUnstaged;

  /// Badge shown on a conflicted file.
  ///
  /// In en, this message translates to:
  /// **'conflict'**
  String get badgeConflict;

  /// Empty state title on the branches page.
  ///
  /// In en, this message translates to:
  /// **'No branches loaded'**
  String get emptyNoBranches;

  /// Empty state message on the branches page.
  ///
  /// In en, this message translates to:
  /// **'Open a repository to list its branches.'**
  String get emptyNoBranchesMessage;

  /// Header of the local branches section.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get branchLocalSection;

  /// Header of the remote branches section.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get branchRemoteSection;

  /// Section header showing the name and number of branches.
  ///
  /// In en, this message translates to:
  /// **'{section} · {count}'**
  String branchSectionTitle(String section, int count);

  /// Action that checks out a local branch.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutButton;

  /// Empty state title on the history page.
  ///
  /// In en, this message translates to:
  /// **'No history loaded'**
  String get emptyNoHistory;

  /// Empty state message on the history page.
  ///
  /// In en, this message translates to:
  /// **'Open a repository to browse its commits.'**
  String get emptyNoHistoryMessage;

  /// Empty state when the repository has no commits.
  ///
  /// In en, this message translates to:
  /// **'No commits yet'**
  String get emptyNoCommits;

  /// Commit list subtitle with short hash and author.
  ///
  /// In en, this message translates to:
  /// **'{oid} · {author}'**
  String commitSubtitle(String oid, String author);

  /// Page title of the settings page.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section for the theme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// Theme mode option that follows the OS.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Light theme option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark theme option.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Settings section for the language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Language option that follows the OS.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// English language option.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Italian language option.
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get languageItalian;

  /// Settings section listing recent repositories.
  ///
  /// In en, this message translates to:
  /// **'Recent repositories'**
  String get settingsRecentRepositories;

  /// Empty state in the recent repositories section.
  ///
  /// In en, this message translates to:
  /// **'No recent repositories.'**
  String get settingsNoRecentRepositories;

  /// Settings section with the engine version.
  ///
  /// In en, this message translates to:
  /// **'Git engine'**
  String get settingsGitEngine;

  /// Engine version label.
  ///
  /// In en, this message translates to:
  /// **'libgit2: {version}'**
  String libgit2Version(String version);

  /// Generic retry action on error views.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// Fallback screen for unknown routes.
  ///
  /// In en, this message translates to:
  /// **'Route not found: {uri}'**
  String routeNotFound(String uri);
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
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
