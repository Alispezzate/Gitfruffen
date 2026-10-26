---
status: complete
updated: 2026-10-26
---

# Workspace UI refactor plan

## Goal
Replicate a modern Git desktop layout: menu, repository tabs, workspace header with breadcrumb and toolbar, refs sidebar with filter, three-column graph, right panel with two modes, terminal placeholder and status bar.

## Decisions
- Diff API in `packages/git_core` (`diffCommit`, `diffWorkingTree`) for stats, WIP row and diff viewer.
- Right panel: Changes by default, Commit details when you select a commit.
- Clicking a file opens the unified diff in the central area; the right panel stays visible.
- Sidebar: Local, Remote, Worktrees, Tags + filter. Cloud/PR/Issues/Teams sections omitted due to missing data.
- Collapsible terminal placeholder, no pty/xterm dependency.
- Menu: `PlatformMenuBar` on macOS, Material `MenuBar` in-window on Windows/Linux (`PlatformMenuBar` does not render on Windows/Linux).
- `ActivityRail` removed; Settings in the menu, in the status bar and in the command palette.
- Graph: BRANCH / TAG, GRAPH, COMMIT MESSAGE columns; author/date/SHA only in the details.
- Path/Tree client-side; Tree groups by directory without collapse.
- Amend commit supported; Compose with AI out of scope.

## Completed phases
1. **git_core diff engine**: `DiffLine`, `DiffHunk`, `DiffFile`, `DiffResult` entities; `diffCommit` and `diffWorkingTree` methods; libgit2 mapping (tree-to-tree, tree-to-index, index-to-workdir), root commit against empty tree, untracked, rename, binary; deterministic fake datasource; tests.
2. **RepositoryBloc**: `stagedDiff`, `unstagedDiff`, `selectedCommitOid`, `commitDiff`, `isLoadingCommitDiff`, `diffFailure`; `CommitSelected`, `CommitSelectionCleared` events; `CommitSubmitted(message, {amend})`; tests.
3. **Chrome**: `WorkspaceMenuBar`, `WorkspaceHeader`, `StatusBar` with gear, removal of `ActivityRail`, desktop dark theme, shared `WorkspaceCommands`.
4. **Refs sidebar** with filter and collapsible sections; working tree and composer removed from the sidebar.
5. **Graph** as a single list with three columns, WIP row with stats, full-width selection, infinite pagination preserved.
6. **Right panel**: `ChangesPanel`, `CommitComposer` (summary 72, description, amend), `CommitDetailsPanel`, `FileDiffView`, `ChangedFilesList` with Path/Tree. Diff opened in the center.
7. **Terminal placeholder** `TerminalPanel` with toggle from the toolbar.
8. **l10n EN/IT**, widget/bloc tests, analyze and format.

## Main files
New:
- `packages/git_core/lib/src/domain/entities/diff.dart`
- `apps/gitfruffen/lib/core/widgets/workspace_menu_bar.dart`
- `apps/gitfruffen/lib/core/widgets/workspace_commands.dart`
- `apps/gitfruffen/lib/features/repository/presentation/widgets/workspace_header.dart`
- `apps/gitfruffen/lib/features/repository/presentation/widgets/changes_panel.dart`
- `apps/gitfruffen/lib/features/repository/presentation/widgets/changed_files_list.dart`
- `apps/gitfruffen/lib/features/repository/presentation/widgets/commit_composer.dart`
- `apps/gitfruffen/lib/features/repository/presentation/widgets/commit_details_panel.dart`
- `apps/gitfruffen/lib/features/repository/presentation/widgets/file_diff_view.dart`
- `apps/gitfruffen/lib/features/repository/presentation/widgets/terminal_panel.dart`

Removed:
- `apps/gitfruffen/lib/core/widgets/activity_rail.dart`
- `apps/gitfruffen/lib/features/repository/presentation/widgets/repository_toolbar.dart`
- `apps/gitfruffen/lib/features/repository/presentation/widgets/working_tree.dart`
- `apps/gitfruffen/lib/features/repository/presentation/widgets/file_change_tile.dart`

## Verification
- `fvm dart analyze apps/gitfruffen`: no issues.
- `fvm flutter test` in `apps/gitfruffen`: 50 tests passed.
- `fvm flutter test` in `packages/git_core`: 18 tests passed.
- `fvm dart format` and `fvm flutter gen-l10n` run.

## Deferred
- Real terminal (pty/xterm).
- File editor, Blame, History, Stage File from the file view.
- Folder collapse in Tree mode.
- Compose commits with AI.
- Cloud Patches / Pull Requests / Issues / Teams sections.
- Horizontal scrolling of lanes beyond 200px.

## Operational notes
- `melos` is not in PATH; use FVM.
- Generated l10n files must not be edited by hand.
- `PlatformMenuBar` is native only on macOS; on Windows/Linux the Material MenuBar is used.
