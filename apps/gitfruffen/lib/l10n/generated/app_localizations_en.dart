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
  String get cloneTabSubtitle =>
      'Clone a remote repository into a local folder.';

  @override
  String get newRepositoryMenuItem => 'New repository…';

  @override
  String get newRepositoryTab => 'New';

  @override
  String get newRepositoryDialogTitle => 'New repository';

  @override
  String get newRepositorySubtitle =>
      'Create a new Git repository in an empty or existing folder.';

  @override
  String get newRepositoryConfirmButton => 'Create';

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
  String get fetchTooltip => 'Fetch';

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
  String get worktreesSection => 'Worktrees';

  @override
  String get tagsSection => 'Tags';

  @override
  String get removeWorktreeTooltip => 'Remove worktree';

  @override
  String get deleteBranchTooltip => 'Delete branch';

  @override
  String get deleteBranchDialogTitle => 'Delete branch';

  @override
  String deleteBranchDialogMessage(String branch) {
    return 'Delete branch $branch? This cannot be undone.';
  }

  @override
  String branchAheadBehind(int ahead, int behind) {
    return '↑$ahead ↓$behind';
  }

  @override
  String get pushTooltip => 'Push';

  @override
  String get pullTooltip => 'Pull';

  @override
  String get createBranchTooltip => 'Create branch';

  @override
  String get stashTooltip => 'Stash changes';

  @override
  String get undoTooltip => 'Undo';

  @override
  String get redoTooltip => 'Redo';

  @override
  String get createBranchDialogTitle => 'Create branch';

  @override
  String get branchNameLabel => 'Branch name';

  @override
  String get createBranchConfirmButton => 'Create';

  @override
  String get stashDialogTitle => 'Stash changes';

  @override
  String get stashMessageLabel => 'Message (optional)';

  @override
  String get stashConfirmButton => 'Stash';

  @override
  String get undoDialogTitle => 'Undo';

  @override
  String get undoDialogMessage =>
      'Move HEAD back one step? Staged changes return to the working tree.';

  @override
  String get redoDialogTitle => 'Redo';

  @override
  String get redoDialogMessage => 'Re-apply the last undone HEAD position?';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get stageAllButton => 'Stage all';

  @override
  String get unstageAllButton => 'Unstage all';

  @override
  String get stageFileTooltip => 'Stage file';

  @override
  String get unstageFileTooltip => 'Unstage file';

  @override
  String get commitMessageHint => 'Commit message';

  @override
  String get commitButton => 'Commit';

  @override
  String changesOnBranch(int count, String branch) {
    return '$count file changes on $branch';
  }

  @override
  String get pathView => 'Path';

  @override
  String get treeView => 'Tree';

  @override
  String get stageAllChanges => 'Stage All Changes';

  @override
  String get unstageAllChanges => 'Unstage All Changes';

  @override
  String get unstagedFiles => 'Unstaged Files';

  @override
  String get stagedFiles => 'Staged Files';

  @override
  String get commitSummaryLabel => 'Commit summary';

  @override
  String get commitDescriptionLabel => 'Description';

  @override
  String get amendPreviousCommit => 'Amend previous commit';

  @override
  String get backToChanges => 'Back to changes';

  @override
  String get closeFileView => 'Close file';

  @override
  String get diffBinaryFile => 'Binary file';

  @override
  String get diffNoChanges => 'No changes';

  @override
  String fileChangesSummary(int count) {
    return '$count files changed';
  }

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
  String get graphColumnDescription => 'Description';

  @override
  String get graphColumnAuthor => 'Author';

  @override
  String get graphColumnDate => 'Date';

  @override
  String get graphColumnSha => 'SHA';

  @override
  String get graphColumnBranchTag => 'BRANCH / TAG';

  @override
  String get graphColumnGraph => 'GRAPH';

  @override
  String get graphColumnMessage => 'COMMIT MESSAGE';

  @override
  String get wipLabel => 'WIP';

  @override
  String get commitDetailsEmpty => 'Select a commit';

  @override
  String get commitDetailsHint => 'Pick a commit in the graph to inspect it.';

  @override
  String get commitCommitterLabel => 'Committer';

  @override
  String get commitParentsLabel => 'Parents';

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
  String get settingsGit => 'Git';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutDescription =>
      'A native desktop Git client built with Flutter.';

  @override
  String libgit2Version(String version) {
    return 'libgit2: $version';
  }

  @override
  String get retryButton => 'Retry';

  @override
  String get commandPaletteHint => 'Type a command...';

  @override
  String get quickOpenHint => 'Search open repositories...';

  @override
  String get paletteNoResults => 'No results';

  @override
  String get copyShaButton => 'Copy SHA';

  @override
  String get menuFile => 'File';

  @override
  String get menuEdit => 'Edit';

  @override
  String get menuView => 'View';

  @override
  String get menuRepository => 'Repository';

  @override
  String get menuHelp => 'Help';

  @override
  String get menuOpenRepository => 'Open Repository';

  @override
  String get menuCloneRepository => 'Clone Repository';

  @override
  String get menuNewRepository => 'New Repository';

  @override
  String get menuCloseRepository => 'Close Repository';

  @override
  String get menuUndo => 'Undo';

  @override
  String get menuRedo => 'Redo';

  @override
  String get menuCommandPalette => 'Command Palette';

  @override
  String get menuSettings => 'Settings';

  @override
  String get menuAbout => 'About Gitfruffen';

  @override
  String get searchTooltip => 'Search';

  @override
  String get actionsTooltip => 'Actions';

  @override
  String get branchTooltip => 'Branch';

  @override
  String get popTooltip => 'Pop';

  @override
  String get terminalTitle => 'Terminal';

  @override
  String get terminalUnavailable => 'Terminal is not available in this build.';

  @override
  String get terminalToggleTooltip => 'Toggle terminal';

  @override
  String get closeTerminalTooltip => 'Close terminal';

  @override
  String get collapseTerminalTooltip => 'Collapse terminal';

  @override
  String get filterHint => 'Filter branches, worktrees and tags';

  @override
  String routeNotFound(String uri) {
    return 'Route not found: $uri';
  }
}
