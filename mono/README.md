# mono

CLI for managing Dart/Flutter monorepos.

## Install (from workspace)

Run from the workspace root (Dart >= 3.5 with workspaces):

```bash
dart pub get
dart pub global activate --source path mono
```

Or run directly from source during development:

```bash
dart run mono:mono <args>
```

## Quick start

```bash
# 1) Create config and scaffolding
mono setup

# 2) Detect packages by pubspec and cache list
mono scan

# 3) See what was detected
mono list packages

# 4) Run pub get across all packages (dependency order by default)
mono get all
```

## Commands

- setup
  - Creates `mono.yaml` (if missing)
  - Creates `monocfg/` with `mono_projects.yaml` and `tasks.yaml` (if missing)
- scan
  - Scans workspace for `pubspec.yaml` and writes `monocfg/mono_projects.yaml`
- list packages|groups|tasks
  - Reads from `mono.yaml` and `monocfg/*`
- get [targets]
  - Runs `flutter pub get` for Flutter packages, `dart pub get` for Dart packages
  - Targets: `all`, `:group`, `glob*`, `packageName`
  - Options: `-j, --concurrency <n>`, `--order dependency|none`, `--dry-run`

## Target selection

Examples:

```bash
mono get all
mono get :apps
mono get core_*
mono get app,ui,core
```

- Uses dependency order by default; disable with `--order none`

## Configuration

Root file `mono.yaml` (created by `mono setup`):

```yaml
settings:
  monocfgPath: monocfg
  concurrency: auto
  defaultOrder: dependency
include:
  - "**"
exclude:
  - "monocfg/**"
  - ".dart_tool/**"
groups: {}
tasks: {}
```

- settings.monocfgPath: path to the config folder
- include/exclude: globs for scanning `pubspec.yaml`
- groups: map of groupName -> list of members (names, globs, or nested ":group")
- tasks: task definitions (merged with `monocfg/tasks.yaml`)

## monocfg folder

- monocfg/mono_projects.yaml

```yaml
packages:
  - name: app
    path: apps/app
    kind: flutter
```

- monocfg/tasks.yaml (optional)

```yaml
build:
  plugin: exec
  run:
    - dart run build_runner build --delete-conflicting-outputs
```

Notes:

- Tasks are merged on top of `mono.yaml` tasks.
- `plugin: exec` lets you define arbitrary shell commands per package.

## Concurrency

- `-j, --concurrency <n>` CLI flag overrides `settings.concurrency`
- `auto` picks a heuristic based on available CPUs

## Dependency order

- `dependency` (default): topological order using local path/name deps
- `none`: keep input/selection order

## Project groups

Define named groups in `mono.yaml` to target multiple packages at once. Members can be package names, globs, or other groups (prefixed with `:`):

```yaml
groups:
  apps:
    - app
    - ui_*
  mobile:
    - :apps # include everything from the apps group
    - flutter_* # and any packages matching this glob
```

Usage examples:

```bash
mono list groups
mono get :apps
mono get :mobile --order none
```

Notes:

- Group expansion supports nesting (e.g. `:mobile` includes `:apps`).
- Globs match against package names (not paths).

## Custom tasks (custom commands)

You can define reusable tasks under `tasks` in `mono.yaml` or `monocfg/tasks.yaml`. These are merged, with `monocfg/tasks.yaml` taking precedence. The built-in `exec` plugin lets you run shell commands in each target package.

Example (`monocfg/tasks.yaml`):

```yaml
build:
  plugin: exec
  run:
    - dart run build_runner build --delete-conflicting-outputs

format:
  plugin: exec
  run:
    - dart format .

test:
  plugin: exec
  run:
    - dart test
```

Discover tasks:

```bash
mono list tasks
```

Notes:

- `plugin: exec` runs each `run` entry as a command in the package directory.
- You can set environment variables with `env:` and express dependencies between tasks with `dependsOn:` in `mono.yaml`.
- Tasks in `monocfg/tasks.yaml` override/extend those in `mono.yaml`.
