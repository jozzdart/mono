import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

import 'package:mono/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

Future<void> main(List<String> argv) async {
  // Pre-parse to compute pretty logging configuration with defaults (A):
  // color=true, icons=true, timestamp=false. Only override when flags are provided.
  const parser = ArgsCliParser();
  final inv = parser.parse(argv);
  bool _boolOpt(String key, bool defaultValue) {
    final list = inv.options[key];
    if (list == null || list.isEmpty) return defaultValue;
    final v = list.first.toLowerCase();
    return v == 'true' || v == '1' || v == 'yes';
  }

  final pretty = PrettyLogger(PrettyLogConfig(
    showColors: _boolOpt('color', true),
    showIcons: _boolOpt('icons', true),
    showTimestamp: _boolOpt('timestamp', false),
  ));

  final wiring = CliWiring(
    workspaceConfig: const FileWorkspaceConfig(),
    prompter: const ConsolePrompter(),
    parser: parser,
    configLoader: const YamlConfigLoader(),
    configValidator: const YamlConfigValidator(),
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
