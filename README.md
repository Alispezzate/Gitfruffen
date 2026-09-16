# Gitfruffen

A modern Git client for desktop (Windows, macOS, Linux) built with Flutter.
Gitfruffen aims to replace GitKraken's UI/UX while keeping the raw performance
of a native Flutter application.

## Architecture

This is a [Melos](https://melos.invertase.dev) monorepo:

| Package | Description |
| --- | --- |
| `apps/gitfruffen` | Flutter desktop application (presentation, DI, routing, theme). |
| `packages/git_core` | Pure Dart Git engine: domain entities, repository contracts, libgit2 datasource. |

### State management: Pine

Gitfruffen uses the [Pine](https://pub.dev/packages/pine) architecture by
[angeloavv](https://github.com/angeloavv) / MyLittleSuite. Pine combines
`provider` for dependency injection with `flutter_bloc` for state management and
injects dependencies top-down in four layers:

1. **mappers** - convert data-layer objects into presentation entities.
2. **providers** - services / datasources (libgit2 access, settings, file picker).
3. **repositories** - abstractions over the data layer.
4. **blocs** - application logic and state.

Each layer may depend on the layers above it and is accessed through Provider's
`context.read()` / `context.watch()`.

### Git engine

Git operations are delegated to [`git2dart`](https://pub.dev/packages/git2dart)
(FFI bindings to libgit2) and fully isolated inside `packages/git_core`. The UI
never talks to libgit2 directly - it only deals with domain entities.

## Getting started

```shell
dart pub global activate melos
melos bootstrap
melos run gen
melos run analyze
melos run test
```

Run the desktop app:

```shell
melos run build:macos   # or build:windows / build:linux
```

## Project layout

```
Gitfruffen/
├── apps/gitfruffen/        # Flutter desktop app
│   └── lib/
│       ├── app.dart
│       ├── core/           # di, router, theme, shared widgets
│       └── features/       # feature-first presentation + blocs
└── packages/git_core/      # Git engine (Dart, no Flutter UI)
    └── lib/src/
        ├── domain/         # entities, repository contracts, failures
        ├── data/           # datasources + repository implementations
        └── mappers/        # libgit2 -> domain mappers
```

## License

MIT
