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
  - Packages from scan cache; groups from `monocfg/groups/*.list`; tasks from `mono.yaml` + `monocfg/tasks.yaml`
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
mono build :apps
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

Define named groups under `monocfg/groups/` with one package name per line.

Example file `monocfg/groups/apps.list`:

```text
app
ui
```

Usage examples:

```bash
mono list groups
mono get :apps
mono get :mobile --order none
```

Notes:

- Group files are simple lists; blank lines and `#` comments are ignored.
- Group names are derived from filenames: `<name>.list` using lowercase slugs `[a-z0-9][a-z0-9-_]*`.

## Custom tasks (custom commands)

You can define reusable tasks under `tasks` in `mono.yaml` or `monocfg/tasks.yaml`. These are merged, with `monocfg/tasks.yaml` taking precedence. The built-in `exec` plugin lets you run shell commands in each target package. Tasks are runnable as top-level commands: `mono <task> [targets]`.

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

- `plugin: exec` runs the first `run` entry as a command in the package directory (additional entries can be added later).
- You can set environment variables with `env:` and express dependencies between tasks with `dependsOn:` in `mono.yaml`.
- Tasks in `monocfg/tasks.yaml` override/extend those in `mono.yaml`.
