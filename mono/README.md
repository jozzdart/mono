# mono

The fast, flexible CLI for managing Dart and Flutter monorepos.

Mono helps teams scan, organize, and operate large workspaces with consistent, repeatable workflows. It pairs intelligent target selection and dependency-aware ordering with simple commands you already know.

## Install

Run from your workspace root:

```bash
dart pub get
dart pub global activate mono
```

## Quick start

```bash
# 1) Create config and scaffolding
mono setup

# 2) Detect packages by pubspec and cache list
mono scan

# 3) Inspect what was detected
mono list packages

# 4) Get dependencies across all packages (dependency order by default)
mono get all
```

## Table of Contents

- [Why mono?](#why-mono)
- [Usage](#usage)
- [Commands](#commands)
  - [setup](#setup)
  - [scan](#scan)
  - [list](#list)
  - [get](#get)
  - [format](#format)
  - [test](#test)
  - [tasks](#tasks)
  - [group](#group)
  - [ungroup](#ungroup)
  - [version](#version)
  - [help](#help)
- [Compact command reference](#compact-command-reference)
- [Target selection](#target-selection)
- [Configuration](#configuration)
- [monocfg folder](#monocfg-folder)
- [Project groups](#project-groups)
- [Concurrency and order](#concurrency-and-order)
- [Custom tasks (exec plugin)](#custom-tasks-exec-plugin)
- [Notes and tips](#notes-and-tips)

## Why mono?

- Simple, composable CLI that mirrors Dart/Flutter tooling
- Smart target selection (names, globs, and groups) and dependency-aware ordering
- Safe grouping for higher-level workflows
- Extensible task system via `plugin: exec`

## Usage

```bash
mono <command> [targets] [options]
```

Targets are optional for built-ins (`get`, `format`, `test`) and required for external `exec` tasks. See [Target selection](#target-selection).

## Commands

### setup

Synopsis:

```bash
mono setup
```

Description:

- Creates `mono.yaml` if missing
- Creates `monocfg/` with `mono_projects.yaml`, `tasks.yaml`, and `groups/` if missing

Examples:

```bash
mono setup
```

### scan

Synopsis:

```bash
mono scan
```

Description:

- Scans the workspace for `pubspec.yaml` using `include`/`exclude` globs
- Writes the cache to `monocfg/mono_projects.yaml`

Examples:

```bash
mono scan
```

### list

Synopsis:

```bash
mono list packages|groups|tasks
```

Description:

- `packages`: Prints cached projects (falls back to a quick scan if empty)
- `groups`: Prints groups from `monocfg/groups/*.list` with members
- `tasks`: Prints merged tasks from `mono.yaml` + `monocfg/tasks.yaml`

Examples:

```bash
mono list packages
mono list groups
mono list tasks
```

### get

Synopsis:

```bash
mono get [targets]
```

Description:

- Runs `flutter pub get` for Flutter packages and `dart pub get` for Dart packages

Options:

- `-j, --concurrency <n>`
- `--order dependency|none`
- `--dry-run`

Examples:

```bash
mono get all
mono get :apps
mono get core_*
```

### format

Synopsis:

```bash
mono format [targets] [--check]
```

Description:

- Runs `dart format .` on each target (write by default)
- `--check` runs `dart format --output=none --set-exit-if-changed .`

Options: same as [get](#get) plus `--check`.

Examples:

```bash
mono format all
mono format :apps --check
```

### test

Synopsis:

```bash
mono test [targets]
```

Description:

- Runs `flutter test` for Flutter packages and `dart test` for Dart packages

Options: same as [get](#get).

Examples:

```bash
mono test all
mono test ui
```

### tasks

Synopsis:

```bash
mono tasks
```

Description:

- Prints all merged tasks with their plugin

Examples:

```bash
mono tasks
```

### group

Synopsis:

```bash
mono group <name>
```

Description:

- Interactively select packages for the group and save to `monocfg/groups/<name>.list`
- Prevents conflicts (cannot use a package name as a group name)
- Prompts to overwrite if the group already exists

Examples:

```bash
mono group apps
```

### ungroup

Synopsis:

```bash
mono ungroup <name>
```

Description:

- Confirms and removes `monocfg/groups/<name>.list`

Examples:

```bash
mono ungroup apps
```

### version

Synopsis:

```bash
mono version | -v | --version
```

Description:

- Prints the CLI version

### help

Synopsis:

```bash
mono help
```

Description:

- Prints usage instructions

## Compact command reference

- `mono setup`  
  Creates _mono.yaml_ if missing. Creates _monocfg/_ with _mono_projects.yaml_, _tasks.yaml_, and _groups/_ if missing.
- `mono scan`  
  Scans the workspace for _pubspec.yaml_ using _include_/_exclude_ globs. Writes the cache to _monocfg/mono_projects.yaml_.
- `mono list packages`  
  Prints cached projects (falls back to a quick scan if empty). Prints groups from _monocfg/groups/\*.list_ with members. Prints merged tasks from _mono.yaml_ + _monocfg/tasks.yaml_.
- `mono list groups`  
  Prints groups from _monocfg/groups/\*.list_ with members.
- `mono list tasks`  
  Prints merged tasks from _mono.yaml_ + _monocfg/tasks.yaml_.
- `mono get [targets]`  
  Runs _flutter pub get_ for Flutter packages and _dart pub get_ for Dart packages.
- `mono format [targets] [--check]`  
  Runs _dart format ._ on each target (write by default). _--check_ runs _dart format --output=none --set-exit-if-changed ._
- `mono test [targets]`  
  Runs _flutter test_ for Flutter packages and _dart test_ for Dart packages.
- `mono tasks`  
  Prints all merged tasks with their plugin.
- `mono group <name>`  
  Interactively select packages for the group and save to _monocfg/groups/\<name\>.list_. Prevents conflicts (cannot use a package name as a group name). Prompts to overwrite if the group already exists.
- `mono ungroup <name>`  
  Confirms and removes _monocfg/groups/\<name\>.list_.
- `mono version` / `-v` / `--version`  
  Prints the CLI version.
- `mono help` or no args  
  Prints usage instructions.

## Target selection

Targets can be mixed and comma‑separated:

```bash
mono get all
mono get :apps
mono get core_*
mono get app,ui,core
mono build :apps
```

- Default order is dependency-based; disable with `--order none`
- Tokens:
  - `all` – all packages
  - `:group` – named group from `monocfg/groups/<name>.list`
  - `glob*` – glob match by package name
  - `name` – exact package name

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

- `settings.monocfgPath`: path to the config folder
- `include`/`exclude`: globs for scanning `pubspec.yaml`
- `groups`: map of groupName -> list (names, globs, or nested `:group`)
- `tasks`: task definitions (merged with `monocfg/tasks.yaml`)

## monocfg folder

- `monocfg/mono_projects.yaml`

```yaml
packages:
  - name: app
    path: apps/app
    kind: flutter
```

- `monocfg/tasks.yaml` (optional)

```yaml
build:
  plugin: exec
  run:
    - dart run build_runner build --delete-conflicting-outputs
```

Notes:

- Tasks are merged on top of `mono.yaml` tasks
- `plugin: exec` lets you define arbitrary shell commands per package

## Concurrency and order

- `-j, --concurrency <n>` overrides `settings.concurrency`; `auto` picks a heuristic based on available CPUs
- Order:
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

- Group files are simple lists; blank lines and `#` comments are ignored
- Group names are derived from filenames: `<name>.list` using lowercase slugs `[a-z0-9][a-z0-9-_]*`

## Custom tasks (exec plugin)

You can define reusable tasks under `tasks` in `mono.yaml` or `monocfg/tasks.yaml`. These are merged, with `monocfg/tasks.yaml` taking precedence. Tasks are runnable as top‑level commands: `mono <task> [targets]`.

Example (`monocfg/tasks.yaml`):

```yaml
build:
  plugin: exec
  run:
    - dart run build_runner build --delete-conflicting-outputs

lint:
  plugin: exec
  run:
    - dart analyze .

format:
  plugin: exec
  run:
    - dart format .
```

Discover tasks:

```bash
mono list tasks
```

Notes:

- External (exec) tasks require explicit targets; use `all` to run on all packages
- Built-in commands like `get`, `format`, and `test` run on all packages when no targets are given
- You can set environment variables with `env:` and express dependencies between tasks with `dependsOn:` in `mono.yaml`
- Tasks in `monocfg/tasks.yaml` override/extend those in `mono.yaml`

## Notes and tips

- Use `mono help` (or run `mono` with no arguments) anytime to see usage
- Combine selectors in one run, e.g. `mono get app,core_*,:apps`
- Tune parallelism with `-j, --concurrency`; `auto` uses a CPU-based heuristic
- For tasks using `plugin: exec`, pass explicit targets (e.g., `all` or `:group`)
- Run `mono list packages|groups|tasks` to confirm what will be affected before executing
