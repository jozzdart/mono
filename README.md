![Mono](https://github.com/jozzdart/mono/blob/main/assets/mono_banner.png?raw=true)

<h3 align="center"><i>The fast, flexible CLI for managing Dart and Flutter monorepos</i></h3>
<p align="center">
        <img src="https://img.shields.io/codefactor/grade/github/jozzdart/mono/main?style=flat-square">
        <img src="https://img.shields.io/github/license/jozzdart/mono?style=flat-square">
        <img src="https://img.shields.io/pub/points/mono?style=flat-square">
        <img src="https://img.shields.io/pub/v/mono?style=flat-square">
        
</p>
<p align="center">
  <a href="https://buymeacoffee.com/yosefd99v" target="https://buymeacoffee.com/yosefd99v">
    <img src="https://img.shields.io/badge/Buy%20me%20a%20coffee-Support (:-blue?logo=buymeacoffee&style=flat-square" />
  </a>
</p>

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
- [Compact command reference](#compact-command-reference)
- [Target selection](#target-selection)
- [Configuration](#configuration)
- [monocfg folder](#monocfg-folder)
- [Project groups](#project-groups)
- [Concurrency and order](#concurrency-and-order)
- [Custom tasks (exec plugin)](#custom-tasks-exec-plugin)
- [Notes and tips](#notes-and-tips)

### Quick links

[setup](#setup) | [scan](#scan) | [list](#list) | [get](#get) | [format](#format) | [test](#test) | [tasks](#tasks) | [group](#group) | [ungroup](#ungroup) | [version](#version) | [help](#help)

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

# Commands

### `setup`

**What it does**: Creates base config files and folders if they don't exist.

```bash
mono setup
```

#### Notes

- Creates `mono.yaml` if missing
- Creates `monocfg/` with `mono_projects.yaml`, `tasks.yaml`, and `groups/` if missing

---

### `scan`

**What it does**: Scans the workspace for projects and caches the results.

```bash
mono scan
```

- Scans the workspace for `pubspec.yaml` using `include`/`exclude` globs
- Writes the cache to `monocfg/mono_projects.yaml`

---

### `list`

**What it does**: Lists cached packages, defined groups, or merged tasks.

```bash
mono list packages|groups|tasks
```

- `packages`: Prints cached projects (falls back to a quick scan if empty)
- `groups`: Prints groups from `monocfg/groups/*.list` with members
- `tasks`: Prints merged tasks from `mono.yaml` + `monocfg/tasks.yaml`

#### Examples

```bash
mono list packages
mono list groups
mono list tasks
```

---

### `get`

**What it does**: Runs `flutter pub get` for Flutter packages and `dart pub get` for Dart packages.

```bash
mono get [targets]
```

- Targets are optional; omit them to run on all packages

#### Options

| Flag                    | Description                | Default         | Example      |                |
| ----------------------- | -------------------------- | --------------- | ------------ | -------------- |
| `-j, --concurrency <n>` | Max parallel executions    | `auto`          | `-j 8`       |                |
| `--order dependency     | none`                      | Execution order | `dependency` | `--order none` |
| `--dry-run`             | Print plan without running | `false`         | `--dry-run`  |                |

#### Examples

```bash
mono get
mono get all
mono get :apps
mono get core_*
```

---

### `format`

**What it does**: Formats Dart code in each target package.

```bash
mono format [targets] [--check]
```

- Runs `dart format .` on each target (write by default)
- `--check` runs `dart format --output=none --set-exit-if-changed .`

#### Options

| Flag                    | Description                          | Default         | Example      |                |
| ----------------------- | ------------------------------------ | --------------- | ------------ | -------------- |
| `-j, --concurrency <n>` | Max parallel executions              | `auto`          | `-j 8`       |                |
| `--order dependency     | none`                                | Execution order | `dependency` | `--order none` |
| `--check`               | Validate formatting only (no writes) | `false`         | `--check`    |                |
| `--dry-run`             | Print plan without running           | `false`         | `--dry-run`  |                |

#### Examples

```bash
mono format all
mono format :apps --check
```

---

### `test`

**What it does**: Runs tests using `flutter test` or `dart test` based on package type.

```bash
mono test [targets]
```

#### Options

| Flag                    | Description                | Default         | Example      |                |
| ----------------------- | -------------------------- | --------------- | ------------ | -------------- |
| `-j, --concurrency <n>` | Max parallel executions    | `auto`          | `-j 8`       |                |
| `--order dependency     | none`                      | Execution order | `dependency` | `--order none` |
| `--dry-run`             | Print plan without running | `false`         | `--dry-run`  |                |

#### Examples

```bash
mono test
mono test ui
```

---

### `tasks`

**What it does**: Prints all merged tasks with their configured plugin.

```bash
mono tasks
```

---

### `group`

**What it does**: Interactively create a named group and select member packages.

```bash
mono group <name>
```

- Interactively select packages for the group and save to `monocfg/groups/<name>.list`
- Prevents conflicts (cannot use a package name as a group name)
- Prompts to overwrite if the group already exists

#### Examples

```bash
mono group apps
```

---

### `ungroup`

**What it does**: Remove a previously created group after confirmation.

```bash
mono ungroup <name>
```

- Confirms and removes `monocfg/groups/<name>.list`

---

### `version`

**What it does**: Prints the CLI version.

- Alias: `-v`, `--version`

#### Examples

```bash
mono version
mono -v
mono --version
```

> Run `mono` with no arguments to see help

---

## Compact command reference

| Command                                 | Summary                                                                  |
| --------------------------------------- | ------------------------------------------------------------------------ |
| [`setup`](#setup)                       | Create `mono.yaml` and `monocfg/` defaults if missing.                   |
| [`scan`](#scan)                         | Scan for `pubspec.yaml` and write cache to `monocfg/mono_projects.yaml`. |
| [`list packages`](#list)                | Print cached projects (quick scan fallback if empty).                    |
| [`list groups`](#list)                  | Print groups from `monocfg/groups/*.list` with members.                  |
| [`list tasks`](#list)                   | Print merged tasks from `mono.yaml` + `monocfg/tasks.yaml`.              |
| [`get [targets]`](#get)                 | Run pub get across targets (Flutter/Dart aware).                         |
| [`format [targets] [--check]`](#format) | Format code; `--check` validates only.                                   |
| [`test [targets]`](#test)               | Run tests across targets.                                                |
| [`tasks`](#tasks)                       | Show all merged tasks with plugin.                                       |
| [`group <name>`](#group)                | Interactively create a group.                                            |
| [`ungroup <name>`](#ungroup)            | Delete a group after confirmation.                                       |
| [`version`](#version)                   | Print CLI version.                                                       |
| [`help`](#help)                         | Show usage instructions.                                                 |

## Target selection

Targets can be mixed and comma‑separated:

#### Examples

```bash
mono get all
mono get :apps
mono get core_*
mono get app,ui,core
mono build :apps
mono get app,core_*,:apps --order none
```

- Default order is dependency-based; disable with `--order none`
- Tokens:
- - `all` – all packages
- - `:group` – named group from `monocfg/groups/<name>.list`
- - `glob*` – glob match by package name
- - `name` – exact package name

> Note: Dependency order ensures dependents see up-to-date local changes. Use `--order none` to preserve your input order when you need strict sequence control.

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

| Key                     | Meaning                                                     | Default                           |
| ----------------------- | ----------------------------------------------------------- | --------------------------------- |
| `settings.monocfgPath`  | Path to the config folder                                   | `monocfg`                         |
| `settings.concurrency`  | Default concurrency                                         | `auto`                            |
| `settings.defaultOrder` | Default execution order                                     | `dependency`                      |
| `include`               | Globs to include when scanning for `pubspec.yaml`           | `["**"]`                          |
| `exclude`               | Globs to exclude when scanning                              | `["monocfg/**", ".dart_tool/**"]` |
| `groups`                | Map of `groupName -> selectors` (names, globs, or `:group`) | `{}`                              |
| `tasks`                 | Task definitions (merged with `monocfg/tasks.yaml`)         | `{}`                              |

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

> Tip: Keep group names short and stable, avoid overlapping membership across groups, and prefer lowercase slugs for consistent anchors.

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

> Tip: External (exec) tasks often work best when combined with named groups (e.g., `mono build :apps`). Use `--dry-run` first to verify the execution plan.

## Notes and tips

- Use `mono help` (or run `mono` with no arguments) anytime to see usage
- Combine selectors in one run, e.g. `mono get app,core_*,:apps`
- Tune parallelism with `-j, --concurrency`; `auto` uses a CPU-based heuristic
- For tasks using `plugin: exec`, pass explicit targets (e.g., `all` or `:group`)
- Run `mono list packages|groups|tasks` to confirm what will be affected before executing
