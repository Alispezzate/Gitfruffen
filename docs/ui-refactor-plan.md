---
status: complete
phase: 5
updated: 2026-10-26
---

# UI refactor plan

## Goal
Bring Gitfruffen's desktop interface to a modern, compact Git layout: activity rail, sidebar with changes and refs, dense graph in the center, details panel on the right, and a persistent status bar.

## Constraints
- Changes limited to `apps/gitfruffen`.
- No new dependencies.
- `packages/git_core` unchanged until a new Git API is needed.
- Existing behavior preserved; strings localized in English and Italian.
- Standard hyphens, never em-dash.

## Decisions
| Decision | Reason |
|---|---|
| Neutral palette with dark surfaces and blue accent | Discreet chrome and semantic colors for Git states |
| 32px graph row height and 16px lanes | Desktop client density |
| Commit box in the left sidebar | The staging flow stays close to changes and refs |
| Right panel for commit details | Separation between navigation and inspection |
| No diff in the right panel for now | `GitRepositoryContract` does not yet expose modified files or diffs |
| 1200px and 1000px breakpoints, minimum window 900x600 | Right panel and sidebar collapse on narrow windows |
| Ctrl/Cmd shortcuts and shared palette | Fast desktop navigation without new packages |
| Context menus on branches and commits | Frequent actions without leaving the context |

## Phase 1: Shell and visual tokens [COMPLETE]
- [x] 1.1 Neutral palette and compact metrics in `core/theme/app_theme.dart`, `app_colors.dart`, `app_typography.dart`.
- [x] 1.2 New `core/widgets/activity_rail.dart` with Repository and Settings.
- [x] 1.3 New `core/widgets/status_bar.dart` with branch, ahead/behind, counts, and path.
- [x] 1.4 `core/widgets/app_shell.dart` with three bands: tabs, rail + page, status bar.
- [x] 1.5 Repository header moved to the left sidebar; removed `core/widgets/sidebar.dart`.
- [x] 1.6 Verification: `dart analyze` clean, 31 tests passed.

## Phase 2: Repository workspace [COMPLETE]
- [x] 2.1 Left sidebar with `WorkingTreeList`, refs, and `CommitComposer` at the bottom (`repository_sidebar.dart`, `working_tree.dart`).
- [x] 2.2 `changes_panel.dart` removed; `file_change_tile.dart` simplified for the sidebar width.
- [x] 2.3 Dense graph with Description/Author/Date/SHA header, inline ref pills, and row selection (`commit_graph_view.dart`, `commit_graph_painter.dart`).
- [x] 2.4 `CommitDetailsPanel` on the right with author, committer, date, SHA, and parent.
- [x] 2.5 `repository_page.dart` with commit selection and responsive three-panel layout.
- [x] 2.6 Compact toolbar with Fetch and Refresh; new `RepositoryFetched` event.
- [x] 2.7 EN/IT l10n strings and generated files updated.
- [x] 2.8 Verification: `flutter gen-l10n` succeeded, `dart analyze` clean, 31 tests passed.

## Phase 3: Tabs, welcome, and settings [COMPLETE]
- [x] 3.1 Compact repository tabs with active indicator and "+" menu for Open/Clone/New; `repository_tabs_test.dart` updated.
- [x] 3.2 Welcome with Open/Clone/New tabbed cards and compact recent list.
- [x] 3.3 Two-column settings with left navigation (Appearance/Git/About).
- [x] 3.4 Shared Open/Clone/New dialogs in `repository_dialogs.dart`; new `RepositoryInitialized` event.

## Phase 4: Desktop interactions [COMPLETE]
- [x] 4.1 Ctrl/Cmd+W, Ctrl/Cmd+Tab, Ctrl/Cmd+P, and Ctrl/Cmd+Shift+P shortcuts.
- [x] 4.2 Shared palette for quick open and command palette, with subsequence filter (`command_palette.dart`, `app_shortcuts.dart`).
- [x] 4.3 Context menus on local branches (checkout/delete) and commits (copy SHA).

## Phase 5: Tests and final verification [COMPLETE]
- [x] 5.1 Widget tests for shell, status bar, commit selection, and welcome; unit test for the palette filter; test for the new initialization event.
- [x] 5.2 `dart format`, `dart analyze`, `flutter test`: 40 tests passed.
- [x] 5.3 Breakpoints verified: right panel from 1200px, sidebar from 1000px; minimum window 900x600.
- [x] 5.4 Fix: graph footer no longer shows an infinite spinner when there are no more pages.

## Deferred
- Diff viewer and file list in the right panel: require a new API in `git_core` (modified files and diff).
- Multiple themes: out of scope.
- Layout below 900px: out of desktop scope.

## Operational notes
- `melos` is not in PATH in this environment; use the FVM equivalents inside `apps/gitfruffen`.
- Generated l10n files must not be edited by hand: run `flutter gen-l10n`.
- Verification commands used: `fvm dart analyze apps/gitfruffen` and `fvm flutter test` inside `apps/gitfruffen`.
