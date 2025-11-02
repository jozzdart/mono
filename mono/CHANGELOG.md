## 0.0.4

- Commands now use a centralized environment builder. Behavior is unchanged; this improves reliability and future extensibility.

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
