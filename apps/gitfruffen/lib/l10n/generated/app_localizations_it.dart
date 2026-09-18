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
  String libgit2Version(String version) {
    return 'libgit2: $version';
  }

  @override
  String get retryButton => 'Riprova';

  @override
  String routeNotFound(String uri) {
    return 'Percorso non trovato: $uri';
  }
}
