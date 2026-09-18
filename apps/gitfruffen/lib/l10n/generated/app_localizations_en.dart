// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Gitfruffen';

  @override
  String get welcomeTagline => 'A fast, native Git client for your desktop.';

  @override
  String get openRepositoryTitle => 'Open a repository';

  @override
  String get openRepositorySubtitle =>
      'Select a local folder containing a Git repository.';

  @override
  String get openRepositoryDialogTitle => 'Open repository';

  @override
  String get openRepositoryTooltip => 'Open a repository';

  @override
  String get browseButton => 'Browse…';

  @override
  String get cloneButton => 'Clone…';

  @override
  String get cloneDialogTitle => 'Clone repository';

  @override
  String get remoteUrlLabel => 'Remote URL';

  @override
  String get localPathLabel => 'Local path';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get cloneConfirmButton => 'Clone';

  @override
  String get recentTitle => 'Recent';

  @override
  String get navRepository => 'Repository';

  @override
  String get navHistory => 'History';

  @override
  String get navBranches => 'Branches';

  @override
  String get navSettings => 'Settings';

  @override
  String get noRepository => 'No repository';

  @override
  String get appVersion => 'Gitfruffen 0.1.0';

  @override
  String get closeRepositoryTooltip => 'Close repository';

  @override
  String get openButton => 'Open';

  @override
  String get emptyNoRepository => 'No repository open';

  @override
  String get emptyNoRepositoryMessage =>
      'Open a repository from the welcome screen.';

  @override
  String get openingRepository => 'Opening…';

  @override
  String get refreshTooltip => 'Refresh';

  @override
  String get stagedLabel => 'Staged';

  @override
  String get unstagedLabel => 'Unstaged';

  @override
  String get conflictedLabel => 'Conflicted';

  @override
  String get totalLabel => 'Total';

  @override
  String get changesTitle => 'Changes';

  @override
  String get workingTreeClean => 'Working tree clean';

  @override
  String fileChangeFrom(String path) {
    return 'from $path';
  }

  @override
  String get badgeStaged => 'staged';

  @override
  String get badgeUnstaged => 'unstaged';

  @override
  String get badgeConflict => 'conflict';

  @override
  String get emptyNoBranches => 'No branches loaded';

  @override
  String get emptyNoBranchesMessage =>
      'Open a repository to list its branches.';

  @override
  String get branchLocalSection => 'Local';

  @override
  String get branchRemoteSection => 'Remote';

  @override
  String branchSectionTitle(String section, int count) {
    return '$section · $count';
  }

  @override
  String get checkoutButton => 'Checkout';

  @override
  String get emptyNoHistory => 'No history loaded';

  @override
  String get emptyNoHistoryMessage =>
      'Open a repository to browse its commits.';

  @override
  String get emptyNoCommits => 'No commits yet';

  @override
  String commitSubtitle(String oid, String author) {
    return '$oid · $author';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get settingsRecentRepositories => 'Recent repositories';

  @override
  String get settingsNoRecentRepositories => 'No recent repositories.';

  @override
  String get settingsGitEngine => 'Git engine';

  @override
  String libgit2Version(String version) {
    return 'libgit2: $version';
  }

  @override
  String get retryButton => 'Retry';

  @override
  String routeNotFound(String uri) {
    return 'Route not found: $uri';
  }
}
