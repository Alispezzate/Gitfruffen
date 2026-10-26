// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Gitfruffen';

  @override
  String get welcomeTagline =>
      'Un client Git nativo e veloce per il tuo desktop.';

  @override
  String get openRepositoryTitle => 'Apri un repository';

  @override
  String get openRepositorySubtitle =>
      'Seleziona una cartella locale contenente un repository Git.';

  @override
  String get openRepositoryDialogTitle => 'Apri repository';

  @override
  String get openRepositoryTooltip => 'Apri un repository';

  @override
  String get browseButton => 'Sfoglia…';

  @override
  String get cloneButton => 'Clona…';

  @override
  String get cloneDialogTitle => 'Clona repository';

  @override
  String get remoteUrlLabel => 'URL remoto';

  @override
  String get localPathLabel => 'Percorso locale';

  @override
  String get cancelButton => 'Annulla';

  @override
  String get cloneConfirmButton => 'Clona';

  @override
  String get cloneTabSubtitle =>
      'Clona un repository remoto in una cartella locale.';

  @override
  String get newRepositoryMenuItem => 'Nuovo repository…';

  @override
  String get newRepositoryTab => 'Nuovo';

  @override
  String get newRepositoryDialogTitle => 'Nuovo repository';

  @override
  String get newRepositorySubtitle =>
      'Crea un nuovo repository Git in una cartella vuota o esistente.';

  @override
  String get newRepositoryConfirmButton => 'Crea';

  @override
  String get recentTitle => 'Recenti';

  @override
  String get navRepository => 'Repository';

  @override
  String get navHistory => 'Cronologia';

  @override
  String get navBranches => 'Rami';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get noRepository => 'Nessun repository';

  @override
  String get appVersion => 'Gitfruffen 0.1.0';

  @override
  String get closeRepositoryTooltip => 'Chiudi repository';

  @override
  String get openButton => 'Apri';

  @override
  String get emptyNoRepository => 'Nessun repository aperto';

  @override
  String get emptyNoRepositoryMessage =>
      'Apri un repository dalla schermata iniziale.';

  @override
  String get openingRepository => 'Apertura…';

  @override
  String get refreshTooltip => 'Aggiorna';

  @override
  String get fetchTooltip => 'Fetch';

  @override
  String get stagedLabel => 'In stage';

  @override
  String get unstagedLabel => 'Non in stage';

  @override
  String get conflictedLabel => 'In conflitto';

  @override
  String get totalLabel => 'Totale';

  @override
  String get changesTitle => 'Modifiche';

  @override
  String get workingTreeClean => 'Working tree pulito';

  @override
  String fileChangeFrom(String path) {
    return 'da $path';
  }

  @override
  String get badgeStaged => 'in stage';

  @override
  String get badgeUnstaged => 'non in stage';

  @override
  String get badgeConflict => 'conflitto';

  @override
  String get emptyNoBranches => 'Nessun ramo caricato';

  @override
  String get emptyNoBranchesMessage =>
      'Apri un repository per elencare i suoi rami.';

  @override
  String get branchLocalSection => 'Locali';

  @override
  String get branchRemoteSection => 'Remoti';

  @override
  String branchSectionTitle(String section, int count) {
    return '$section · $count';
  }

  @override
  String get checkoutButton => 'Checkout';

  @override
  String get worktreesSection => 'Worktree';

  @override
  String get tagsSection => 'Tag';

  @override
  String get removeWorktreeTooltip => 'Rimuovi worktree';

  @override
  String get deleteBranchTooltip => 'Elimina ramo';

  @override
  String get deleteBranchDialogTitle => 'Elimina ramo';

  @override
  String deleteBranchDialogMessage(String branch) {
    return 'Eliminare il ramo $branch? L\'operazione non può essere annullata.';
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
  String get createBranchTooltip => 'Crea ramo';

  @override
  String get stashTooltip => 'Metti in stash';

  @override
  String get undoTooltip => 'Annulla';

  @override
  String get redoTooltip => 'Ripeti';

  @override
  String get createBranchDialogTitle => 'Crea ramo';

  @override
  String get branchNameLabel => 'Nome del ramo';

  @override
  String get createBranchConfirmButton => 'Crea';

  @override
  String get stashDialogTitle => 'Metti in stash';

  @override
  String get stashMessageLabel => 'Messaggio (opzionale)';

  @override
  String get stashConfirmButton => 'Stash';

  @override
  String get undoDialogTitle => 'Annulla';

  @override
  String get undoDialogMessage =>
      'Spostare HEAD indietro di un passo? Le modifiche in stage tornano nel working tree.';

  @override
  String get redoDialogTitle => 'Ripeti';

  @override
  String get redoDialogMessage =>
      'Riapplicare l\'ultima posizione di HEAD annullata?';

  @override
  String get confirmButton => 'Conferma';

  @override
  String get stageAllButton => 'Stage di tutto';

  @override
  String get unstageAllButton => 'Rimuovi stage';

  @override
  String get stageFileTooltip => 'Metti in stage';

  @override
  String get unstageFileTooltip => 'Rimuovi dallo stage';

  @override
  String get commitMessageHint => 'Messaggio del commit';

  @override
  String get commitButton => 'Commit';

  @override
  String changesOnBranch(int count, String branch) {
    return '$count modifiche su $branch';
  }

  @override
  String get pathView => 'Percorso';

  @override
  String get treeView => 'Albero';

  @override
  String get stageAllChanges => 'Stage tutte le modifiche';

  @override
  String get unstageAllChanges => 'Rimuovi tutto dallo stage';

  @override
  String get unstagedFiles => 'File non in stage';

  @override
  String get stagedFiles => 'File in stage';

  @override
  String get commitSummaryLabel => 'Riepilogo commit';

  @override
  String get commitDescriptionLabel => 'Descrizione';

  @override
  String get amendPreviousCommit => 'Modifica il commit precedente';

  @override
  String get backToChanges => 'Torna alle modifiche';

  @override
  String get closeFileView => 'Chiudi file';

  @override
  String get diffBinaryFile => 'File binario';

  @override
  String get diffNoChanges => 'Nessuna modifica';

  @override
  String fileChangesSummary(int count) {
    return '$count file modificati';
  }

  @override
  String get emptyNoHistory => 'Nessuna cronologia caricata';

  @override
  String get emptyNoHistoryMessage =>
      'Apri un repository per sfogliare i suoi commit.';

  @override
  String get emptyNoCommits => 'Nessun commit';

  @override
  String commitSubtitle(String oid, String author) {
    return '$oid · $author';
  }

  @override
  String get graphColumnDescription => 'Descrizione';

  @override
  String get graphColumnAuthor => 'Autore';

  @override
  String get graphColumnDate => 'Data';

  @override
  String get graphColumnSha => 'SHA';

  @override
  String get graphColumnBranchTag => 'BRANCH / TAG';

  @override
  String get graphColumnGraph => 'GRAFO';

  @override
  String get graphColumnMessage => 'MESSAGGIO COMMIT';

  @override
  String get wipLabel => 'WIP';

  @override
  String get commitDetailsEmpty => 'Seleziona un commit';

  @override
  String get commitDetailsHint => 'Scegli un commit nel grafo per esaminarlo.';

  @override
  String get commitCommitterLabel => 'Committer';

  @override
  String get commitParentsLabel => 'Parent';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsAppearance => 'Aspetto';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get languageSystem => 'Sistema';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get settingsRecentRepositories => 'Repository recenti';

  @override
  String get settingsNoRecentRepositories => 'Nessun repository recente.';

  @override
  String get settingsGitEngine => 'Motore Git';

  @override
  String get settingsGit => 'Git';

  @override
  String get settingsAbout => 'Informazioni';

  @override
  String get settingsAboutDescription =>
      'Un client Git desktop nativo costruito con Flutter.';

  @override
  String libgit2Version(String version) {
    return 'libgit2: $version';
  }

  @override
  String get retryButton => 'Riprova';

  @override
  String get commandPaletteHint => 'Digita un comando...';

  @override
  String get quickOpenHint => 'Cerca tra i repository aperti...';

  @override
  String get paletteNoResults => 'Nessun risultato';

  @override
  String get copyShaButton => 'Copia SHA';

  @override
  String get menuFile => 'File';

  @override
  String get menuEdit => 'Modifica';

  @override
  String get menuView => 'Vista';

  @override
  String get menuRepository => 'Repository';

  @override
  String get menuHelp => 'Aiuto';

  @override
  String get menuOpenRepository => 'Apri repository';

  @override
  String get menuCloneRepository => 'Clona repository';

  @override
  String get menuNewRepository => 'Nuovo repository';

  @override
  String get menuCloseRepository => 'Chiudi repository';

  @override
  String get menuUndo => 'Annulla';

  @override
  String get menuRedo => 'Ripeti';

  @override
  String get menuCommandPalette => 'Palette comandi';

  @override
  String get menuSettings => 'Impostazioni';

  @override
  String get menuAbout => 'Informazioni su Gitfruffen';

  @override
  String get searchTooltip => 'Cerca';

  @override
  String get actionsTooltip => 'Azioni';

  @override
  String get branchTooltip => 'Ramo';

  @override
  String get popTooltip => 'Pop';

  @override
  String get terminalTitle => 'Terminale';

  @override
  String get terminalUnavailable =>
      'Il terminale non è disponibile in questa build.';

  @override
  String get terminalToggleTooltip => 'Mostra o nascondi il terminale';

  @override
  String get closeTerminalTooltip => 'Chiudi terminale';

  @override
  String get collapseTerminalTooltip => 'Comprimi terminale';

  @override
  String get filterHint => 'Filtra rami, worktree e tag';

  @override
  String routeNotFound(String uri) {
    return 'Percorso non trovato: $uri';
  }
}
