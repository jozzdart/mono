import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

import 'package:mono/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

Future<void> main(List<String> argv) async {
  // Pre-parse flags and load YAML to compute pretty logging configuration
  const parser = ArgsCliParser();
  final inv = parser.parse(argv);
  final loaded = await const FileWorkspaceConfig().loadRootConfig();

  bool? boolOptOrNull(String key) {
    final list = inv.options[key];
    if (list == null || list.isEmpty) return null;
    final v = list.first.toLowerCase();
    if (v == 'true' || v == '1' || v == 'yes') return true;
    if (v == 'false' || v == '0' || v == 'no') return false;
    return null;
  }

  final pretty = PrettyLogger(PrettyLogConfig(
    showColors: boolOptOrNull(OptionKeys.color) ?? loaded.config.logger.color,
    showIcons: boolOptOrNull(OptionKeys.icons) ?? loaded.config.logger.icons,
    showTimestamp:
        boolOptOrNull(OptionKeys.timestamp) ?? loaded.config.logger.timestamp,
  ));

  final wiring = CliWiring(
    workspaceConfig: const FileWorkspaceConfig(),
    prompter: const ConsolePrompter(),
    parser: parser,
    configLoader: const YamlConfigLoader(),
    packageScanner: const FileSystemPackageScanner(),
    graphBuilder: const DefaultGraphBuilder(),
    targetSelector: const DefaultTargetSelector(),
    commandPlanner: const DefaultCommandPlanner(),
    clock: const SystemClock(),
    logger: pretty,
    pathService: const DefaultPathService(),
    envBuilder: const DefaultCommandEnvironmentBuilder(),
    plugins: _plugins,
    taskExecutor: DefaultTaskExecutor(
      processRunner: const DefaultProcessRunner(),
      commandPlanner: const DefaultCommandPlanner(),
    ),
    router: _router,
  );
  final exitCodeValue = await runCli(argv, wiring: wiring);
  // ignore: avoid_print
  exit(exitCodeValue);
}

const _plugins = PluginRegistry({
  'pub': PubPlugin(),
  'exec': ExecPlugin(),
  'format': FormatPlugin(),
  'test': TestPlugin(),
});

// Built-in commands index created in main CLI wiring
const List<Command> _builtInCommands = <Command>[
  HelpCommand(),
  VersionCommand(),
  SetupCommand(),
  ScanCommand(),
  ListCommand(),
  TasksCommand(),
  GetCommand(),
  FormatCommand(),
  TestCommand(),
  GroupCommand(),
  UngroupCommand(),
];

const _router = DefaultCommandRouter(
  helpCommand: HelpCommand(),
  commands: _builtInCommands,
  fallbackCommand: TaskCommand(),
);
