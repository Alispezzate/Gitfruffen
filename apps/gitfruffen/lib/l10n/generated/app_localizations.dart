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

  /// Helper text of the clone tab on the welcome card.
  ///
  /// In en, this message translates to:
  /// **'Clone a remote repository into a local folder.'**
  String get cloneTabSubtitle;

  /// Add menu item that initialises a repository.
  ///
  /// In en, this message translates to:
  /// **'New repository…'**
  String get newRepositoryMenuItem;

  /// Welcome card tab that initialises a repository.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newRepositoryTab;

  /// Title of the new repository dialog.
  ///
  /// In en, this message translates to:
  /// **'New repository'**
  String get newRepositoryDialogTitle;

  /// Helper text of the new repository tab.
  ///
  /// In en, this message translates to:
  /// **'Create a new Git repository in an empty or existing folder.'**
  String get newRepositorySubtitle;

  /// Confirm action of the new repository dialog.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get newRepositoryConfirmButton;

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

  /// Toolbar action that fetches the default remote.
  ///
  /// In en, this message translates to:
  /// **'Fetch'**
  String get fetchTooltip;

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

  /// Header of the worktrees section.
  ///
  /// In en, this message translates to:
  /// **'Worktrees'**
  String get worktreesSection;

  /// Header of the tags section.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsSection;

  /// Tooltip of the worktree remove action.
  ///
  /// In en, this message translates to:
  /// **'Remove worktree'**
  String get removeWorktreeTooltip;

  /// Tooltip of the branch delete action.
  ///
  /// In en, this message translates to:
  /// **'Delete branch'**
  String get deleteBranchTooltip;

  /// Title of the delete branch confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete branch'**
  String get deleteBranchDialogTitle;

  /// Message of the delete branch confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete branch {branch}? This cannot be undone.'**
  String deleteBranchDialogMessage(String branch);

  /// Ahead/behind counters shown as a branch subtitle.
  ///
  /// In en, this message translates to:
  /// **'↑{ahead} ↓{behind}'**
  String branchAheadBehind(int ahead, int behind);

  /// Toolbar action that pushes the current branch.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get pushTooltip;

  /// Toolbar action that pulls the default remote.
  ///
  /// In en, this message translates to:
  /// **'Pull'**
  String get pullTooltip;

  /// Toolbar action that creates a branch.
  ///
  /// In en, this message translates to:
  /// **'Create branch'**
  String get createBranchTooltip;

  /// Toolbar action that stashes working tree changes.
  ///
  /// In en, this message translates to:
  /// **'Stash changes'**
  String get stashTooltip;

  /// Toolbar action that moves HEAD back.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoTooltip;

  /// Toolbar action that re-applies an undone HEAD move.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redoTooltip;

  /// Title of the create branch dialog.
  ///
  /// In en, this message translates to:
  /// **'Create branch'**
  String get createBranchDialogTitle;

  /// Label of the branch name field.
  ///
  /// In en, this message translates to:
  /// **'Branch name'**
  String get branchNameLabel;

  /// Confirm action of the create branch dialog.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createBranchConfirmButton;

  /// Title of the stash dialog.
  ///
  /// In en, this message translates to:
  /// **'Stash changes'**
  String get stashDialogTitle;

  /// Label of the stash message field.
  ///
  /// In en, this message translates to:
  /// **'Message (optional)'**
  String get stashMessageLabel;

  /// Confirm action of the stash dialog.
  ///
  /// In en, this message translates to:
  /// **'Stash'**
  String get stashConfirmButton;

  /// Title of the undo confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoDialogTitle;

  /// Message of the undo confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Move HEAD back one step? Staged changes return to the working tree.'**
  String get undoDialogMessage;

  /// Title of the redo confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get redoDialogTitle;

  /// Message of the redo confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Re-apply the last undone HEAD position?'**
  String get redoDialogMessage;

  /// Generic confirm action in dialogs.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// Action that stages every change.
  ///
  /// In en, this message translates to:
  /// **'Stage all'**
  String get stageAllButton;

  /// Action that unstages every change.
  ///
  /// In en, this message translates to:
  /// **'Unstage all'**
  String get unstageAllButton;

  /// Tooltip of the per-file stage action.
  ///
  /// In en, this message translates to:
  /// **'Stage file'**
  String get stageFileTooltip;

  /// Tooltip of the per-file unstage action.
  ///
  /// In en, this message translates to:
  /// **'Unstage file'**
  String get unstageFileTooltip;

  /// Placeholder of the commit message field.
  ///
  /// In en, this message translates to:
  /// **'Commit message'**
  String get commitMessageHint;

  /// Action that creates a commit from the index.
  ///
  /// In en, this message translates to:
  /// **'Commit'**
  String get commitButton;

  /// Header of the working tree changes panel.
  ///
  /// In en, this message translates to:
  /// **'{count} file changes on {branch}'**
  String changesOnBranch(int count, String branch);

  /// Option that lists changed files by their full path.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get pathView;

  /// Option that groups changed files by directory.
  ///
  /// In en, this message translates to:
  /// **'Tree'**
  String get treeView;

  /// Action that stages every unstaged change.
  ///
  /// In en, this message translates to:
  /// **'Stage All Changes'**
  String get stageAllChanges;

  /// Action that unstages every staged change.
  ///
  /// In en, this message translates to:
  /// **'Unstage All Changes'**
  String get unstageAllChanges;

  /// Header of the unstaged changes section.
  ///
  /// In en, this message translates to:
  /// **'Unstaged Files'**
  String get unstagedFiles;

  /// Header of the staged changes section.
  ///
  /// In en, this message translates to:
  /// **'Staged Files'**
  String get stagedFiles;

  /// Placeholder of the commit summary field.
  ///
  /// In en, this message translates to:
  /// **'Commit summary'**
  String get commitSummaryLabel;

  /// Placeholder of the commit description field.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get commitDescriptionLabel;

  /// Checkbox that amends the HEAD commit.
  ///
  /// In en, this message translates to:
  /// **'Amend previous commit'**
  String get amendPreviousCommit;

  /// Tooltip of the back button in diff and commit views.
  ///
  /// In en, this message translates to:
  /// **'Back to changes'**
  String get backToChanges;

  /// Tooltip of the close button when a file diff is open.
  ///
  /// In en, this message translates to:
  /// **'Close file'**
  String get closeFileView;

  /// Shown instead of a diff for binary files.
  ///
  /// In en, this message translates to:
  /// **'Binary file'**
  String get diffBinaryFile;

  /// Shown when a file or commit has no diff.
  ///
  /// In en, this message translates to:
  /// **'No changes'**
  String get diffNoChanges;

  /// Toolbar toggle that shows blame authorship next to diff lines.
  ///
  /// In en, this message translates to:
  /// **'Blame'**
  String get diffBlame;

  /// Toolbar action that opens the file history dialog.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get diffHistory;

  /// Tooltip of the action that jumps to the previous diff hunk.
  ///
  /// In en, this message translates to:
  /// **'Previous change'**
  String get diffPreviousChange;

  /// Tooltip of the action that jumps to the next diff hunk.
  ///
  /// In en, this message translates to:
  /// **'Next change'**
  String get diffNextChange;

  /// Diff render mode that shows only changed lines.
  ///
  /// In en, this message translates to:
  /// **'Hunk view'**
  String get diffHunkView;

  /// Diff render mode that shows a unified inline diff.
  ///
  /// In en, this message translates to:
  /// **'Inline view'**
  String get diffInlineView;

  /// Diff render mode that shows old and new files side by side.
  ///
  /// In en, this message translates to:
  /// **'Split view'**
  String get diffSplitView;

  /// Toolbar toggle that hides whitespace-only changes.
  ///
  /// In en, this message translates to:
  /// **'Ignore whitespace'**
  String get diffIgnoreWhitespace;

  /// Toolbar toggle that wraps long diff lines.
  ///
  /// In en, this message translates to:
  /// **'Word wrap'**
  String get diffWordWrap;

  /// Title of the dialog listing commits that changed the file.
  ///
  /// In en, this message translates to:
  /// **'File history'**
  String get diffHistoryTitle;

  /// Empty state of the file history dialog.
  ///
  /// In en, this message translates to:
  /// **'No commits touch this file.'**
  String get diffHistoryEmpty;

  /// Loading label of the file history dialog.
  ///
  /// In en, this message translates to:
  /// **'Loading history...'**
  String get diffHistoryLoading;

  /// Loading label shown while blame data is fetched.
  ///
  /// In en, this message translates to:
  /// **'Loading blame...'**
  String get diffBlameLoading;

  /// Shown when blame data could not be loaded.
  ///
  /// In en, this message translates to:
  /// **'Blame unavailable'**
  String get diffBlameUnavailable;

  /// Collapsed row summarising consecutive unchanged diff lines.
  ///
  /// In en, this message translates to:
  /// **'{count} unchanged lines'**
  String diffUnchangedLines(int count);

  /// Number of files changed by the selected commit.
  ///
  /// In en, this message translates to:
  /// **'{count} files changed'**
  String fileChangesSummary(int count);

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

  /// Commit graph column header for the commit summary.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get graphColumnDescription;

  /// Commit graph column header for the author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get graphColumnAuthor;

  /// Commit graph column header for the date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get graphColumnDate;

  /// Commit graph column header for the short object id.
  ///
  /// In en, this message translates to:
  /// **'SHA'**
  String get graphColumnSha;

  /// Commit graph column header for branch and tag labels.
  ///
  /// In en, this message translates to:
  /// **'BRANCH / TAG'**
  String get graphColumnBranchTag;

  /// Commit graph column header for the lane graph.
  ///
  /// In en, this message translates to:
  /// **'GRAPH'**
  String get graphColumnGraph;

  /// Commit graph column header for the commit summary.
  ///
  /// In en, this message translates to:
  /// **'COMMIT MESSAGE'**
  String get graphColumnMessage;

  /// Label of the work-in-progress row above the commit graph.
  ///
  /// In en, this message translates to:
  /// **'WIP'**
  String get wipLabel;

  /// Empty state title of the commit details panel.
  ///
  /// In en, this message translates to:
  /// **'Select a commit'**
  String get commitDetailsEmpty;

  /// Empty state message of the commit details panel.
  ///
  /// In en, this message translates to:
  /// **'Pick a commit in the graph to inspect it.'**
  String get commitDetailsHint;

  /// Label of the committer identity in the commit details panel.
  ///
  /// In en, this message translates to:
  /// **'Committer'**
  String get commitCommitterLabel;

  /// Label of the parent commits in the commit details panel.
  ///
  /// In en, this message translates to:
  /// **'Parents'**
  String get commitParentsLabel;

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

  /// Settings section for repositories and the Git engine.
  ///
  /// In en, this message translates to:
  /// **'Git'**
  String get settingsGit;

  /// Settings section with application information.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Short description shown in the about settings section.
  ///
  /// In en, this message translates to:
  /// **'A native desktop Git client built with Flutter.'**
  String get settingsAboutDescription;

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

  /// Placeholder of the command palette search field.
  ///
  /// In en, this message translates to:
  /// **'Type a command...'**
  String get commandPaletteHint;

  /// Placeholder of the quick open palette search field.
  ///
  /// In en, this message translates to:
  /// **'Search open repositories...'**
  String get quickOpenHint;

  /// Empty state of the command palette list.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get paletteNoResults;

  /// Commit context menu action that copies the full object id.
  ///
  /// In en, this message translates to:
  /// **'Copy SHA'**
  String get copyShaButton;

  /// Application menu that groups repository file actions.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get menuFile;

  /// Application menu that groups editing actions.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get menuEdit;

  /// Application menu that groups view actions.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get menuView;

  /// View menu action that returns to the repository workspace.
  ///
  /// In en, this message translates to:
  /// **'Repository'**
  String get menuRepository;

  /// Application menu that groups help actions.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get menuHelp;

  /// File menu action that opens a local repository.
  ///
  /// In en, this message translates to:
  /// **'Open Repository'**
  String get menuOpenRepository;

  /// File menu action that clones a remote repository.
  ///
  /// In en, this message translates to:
  /// **'Clone Repository'**
  String get menuCloneRepository;

  /// File menu action that initialises a repository.
  ///
  /// In en, this message translates to:
  /// **'New Repository'**
  String get menuNewRepository;

  /// File menu action that closes the active repository.
  ///
  /// In en, this message translates to:
  /// **'Close Repository'**
  String get menuCloseRepository;

  /// Edit menu action that moves HEAD back.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get menuUndo;

  /// Edit menu action that re-applies an undone HEAD move.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get menuRedo;

  /// View menu action that opens the command palette.
  ///
  /// In en, this message translates to:
  /// **'Command Palette'**
  String get menuCommandPalette;

  /// View menu action that opens the settings page.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// Help menu action that opens the about dialog.
  ///
  /// In en, this message translates to:
  /// **'About Gitfruffen'**
  String get menuAbout;

  /// Tooltip of the search button in the workspace header.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTooltip;

  /// Tooltip of the extra actions menu in the workspace header.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actionsTooltip;

  /// Label and tooltip of the branch action in the workspace header.
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branchTooltip;

  /// Label and tooltip of the stash pop action in the workspace header.
  ///
  /// In en, this message translates to:
  /// **'Pop'**
  String get popTooltip;

  /// Title of the terminal panel.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get terminalTitle;

  /// Placeholder shown in the terminal panel.
  ///
  /// In en, this message translates to:
  /// **'Terminal is not available in this build.'**
  String get terminalUnavailable;

  /// Tooltip of the terminal toggle button in the workspace header.
  ///
  /// In en, this message translates to:
  /// **'Toggle terminal'**
  String get terminalToggleTooltip;

  /// Tooltip of the terminal panel close button.
  ///
  /// In en, this message translates to:
  /// **'Close terminal'**
  String get closeTerminalTooltip;

  /// Tooltip of the terminal panel collapse button when it is expanded.
  ///
  /// In en, this message translates to:
  /// **'Collapse terminal'**
  String get collapseTerminalTooltip;

  /// Placeholder of the sidebar filter field.
  ///
  /// In en, this message translates to:
  /// **'Filter branches, worktrees and tags'**
  String get filterHint;

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
