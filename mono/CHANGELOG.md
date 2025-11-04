## 0.0.7

- Default pretty logging (colors + icons, no timestamp); supports `--no-color`, `--no-icons`, `--timestamp`.
- Setup now normalizes `mono.yaml`, adding defaults and fixing invalid values.
- CLI reads `logger` defaults from `mono.yaml`; flags still override.
- Fixed logging output adding unnecessary empty spaces.
- Improved help output style and formatting.

## 0.0.6

- Imported `mono_core` into `mono`
- Updated commands to depend on `mono_core` ports only
- Use pluggable `CliEngine` (default from `mono_cli`), no behavior change
- Updated wiring to pass router factory to engine

## 0.0.5

- Breaking: Switched CLI IO to `Logger` and simplified `runCli` signature.
  - `runCli` is now `Future<int> runCli(List<String> argv, { CliWiring? wiring })`.
  - Command handlers and error/help output use the injected `Logger`.
  - Updated `bin/mono.dart`, tests, and example to the new signature.

## 0.0.4

- Refactor: Commands now delegate execution to a centralized TaskExecutor. Behavior unchanged; see `mono_cli` and `mono_core` changelogs for internals.

## 0.0.3

- New: Built-in commands `format` and `test`.
  - `mono format [targets] [--check]` uses `dart format` (write by default; `--check` verifies formatting).
  - `mono test [targets]` runs `flutter test` for Flutter packages and `dart test` for Dart packages.
- Added comprehensive test coverage for all commands and functionality.

## 0.0.2

- New: File-based groups under `monocfg/groups/*.list` (one package per line).
  - Added `mono group <name>` and `mono ungroup <name>` to create/delete groups.
  - `mono list groups` now reads from `monocfg/groups/`.
  - Group selection UI fixed (space toggles, enter confirms, `q` cancels gracefully).
- New: Run tasks as top-level commands: `mono [taskname] [targets]`.
  - Added `mono tasks` to list all tasks.
  - External (exec) tasks now require explicit targets; use `all` to run on all packages.
  - Built-in commands like `get` still default to all when no targets are given.
- Update: `mono get` uses the new group store for `:group` resolution.
- Docs: README updated with file-based groups and task invocation examples.

## 0.0.1

- Initial release of the Mono CLI with the core CLI functionality: `setup`, `scan`, `get`, `list`
