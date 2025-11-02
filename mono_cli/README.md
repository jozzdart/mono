# mono_cli

Internal implementations powering the Mono CLI.

This package contains the parser, config loader/validator, target selector, planner, runner, and built-in plugins used by the `mono` command.

If you are an end user of the CLI, see the `mono` package README instead.

## Who is this for?

- End users: use the `mono` CLI; see the `mono` package docs.
- Library/CLI developers: import `mono_cli` to embed or extend Mono’s behavior.

## Install / Develop

- In a Dart workspace, add `mono_cli` as a dependency for library usage.
- Developing in this repo: run the CLI through the `mono` package during development.

```bash
dart run mono:mono <args>
```

For CLI installation and full user docs, see the `mono` package README.

## Commands (overview)

- setup: Create `mono.yaml` if missing and scaffold `monocfg/`.
- scan: Detect packages and write `monocfg/mono_projects.yaml`.
- list packages|groups|tasks: List detected packages, file-based groups, or merged tasks.
- get [targets]: Run `flutter pub get` (Flutter) or `dart pub get` (Dart).
  - Options: `-j, --concurrency <n>`, `--order dependency|none`, `--dry-run`.
- format [targets]: Format code across targets; add `--check` to verify only.
  - Options: `--check`, plus common options above.
- test [targets]: Run tests across targets (common options supported).
- group <name>: Interactive creation of a file-based group under `monocfg/groups/`.
- ungroup <name>: Remove a file-based group.
- tasks: List merged tasks (root `mono.yaml` + `monocfg/tasks.yaml`).
- task <name> [targets]: Run a defined task as a top-level command.
- version: Print CLI name and version.

## Target selection

You can select targets using names, groups, and globs:

```bash
mono get all
mono get :apps
mono get core_*
mono get app,ui,core
```

- Default ordering is dependency-based. Disable with `--order none`.

## Configuration (mono.yaml)

`mono setup` creates a starter `mono.yaml`. Key fields:

```yaml
settings:
  monocfgPath: monocfg
  concurrency: auto
  defaultOrder: dependency
  shellWindows: powershell
  shellPosix: bash
include:
  - "**"
exclude:
  - "monocfg/**"
  - ".dart_tool/**"
packages: {} # optional name -> relative path overrides
tasks: {}
```

- settings.monocfgPath: path to the config folder (`monocfg` by default).
- settings.concurrency: number or `auto`.
- settings.defaultOrder: `dependency` or `none`.
- settings.shellWindows/shellPosix: default shells used by the `exec` plugin.
- include/exclude: globs for scanning `pubspec.yaml`.
- packages: map of name → relative path overrides (optional).
- tasks: task definitions (merged with `monocfg/tasks.yaml`).

## monocfg folder

- `monocfg/mono_projects.yaml`: cache of detected packages (written by `scan`).

```yaml
packages:
  - name: app
    path: apps/app
    kind: flutter
```

- `monocfg/tasks.yaml` (optional): user-defined tasks that override/extend root tasks.

```yaml
build:
  plugin: exec
  run:
    - dart run build_runner build --delete-conflicting-outputs
```

Notes:

- Tasks defined in `monocfg/tasks.yaml` override/extend those in `mono.yaml`.
- `plugin: exec` runs shell commands per package directory.

## Groups management (file-based)

Groups are stored as files under `monocfg/groups/` and are managed via commands:

```bash
mono group <name>     # interactive selection and save to monocfg/groups
mono ungroup <name>   # remove file-backed group
mono list groups      # inspect groups and members
```

- Group expansion supports nesting (use `:groupName`).
- Globs match against package names (not paths).

## Tasks and plugins

Built-in plugins:

- pub: supports `get` (and `clean` when invoked via tasks).
- exec: runs shell commands (`run:` lines) in each package.
- format: runs formatter; supports `--check`.
- test: runs test suites.

Tasks can be defined in `mono.yaml` or `monocfg/tasks.yaml` and merged (with `monocfg` taking precedence). You can use `env:` and `dependsOn:`. Top-level task execution maps task names to plugins and commands:

```yaml
format:
  plugin: format

get:
  plugin: pub

lint:
  plugin: exec
  run:
    - dart fix --apply
```

Discover tasks:

```bash
mono list tasks
```

Run a task directly as a command (requires explicit targets for external tasks):

```bash
mono lint all
```

## Library usage examples

Tokenizer and parser:

```dart
final tokenizer = ArgsTokenizer();
final tokens = tokenizer.tokenize('list all --check -t app');
final parser = ArgsCliParser();
final invocation = parser.parse(['list', '--check', 'all', '-t', 'app']);
```

YAML loader and validator:

```dart
const yamlText = '''
include:
  - packages/*
tasks:
  build:
    run: [dart, compile]
''';
const loader = YamlConfigLoader();
final config = loader.load(yamlText);

const validator = YamlConfigValidator();
final issues = validator.validate(config);
```

Planning and running (conceptual):

```dart
final planner = DefaultCommandPlanner();
final task = TaskSpec(id: const CommandId('get'), plugin: const PluginId('pub'));
final plan = planner.plan(task: task, targets: targets);

final plugins = PluginRegistry({
  'pub': PubPlugin(),
  'exec': ExecPlugin(),
  'format': FormatPlugin(),
  'test': TestPlugin(),
});

final runner = Runner(
  processRunner: const DefaultProcessRunner(),
  logger: const StdLogger(),
  options: const RunnerOptions(concurrency: 4),
);
await runner.execute(plan as SimpleExecutionPlan, plugins);
```

## Links

- Mono CLI user guide: mono/README.md
- Changelog: mono_cli/CHANGELOG.md
- Repository: github.com/jozzdart/mono
- Issues: github.com/jozzdart/mono/issues
