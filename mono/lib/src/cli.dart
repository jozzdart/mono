import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

import 'commands/setup.dart';
import 'commands/scan.dart';
import 'commands/get.dart';
import 'commands/format.dart';
import 'commands/test.dart';
import 'commands/list.dart';
import 'commands/group.dart';
import 'commands/ungroup.dart';
import 'commands/version.dart';
import 'commands/tasks.dart';
import 'commands/task.dart';

@immutable
class CliWiring {
  const CliWiring({
    required this.parser,
    required this.configLoader,
    required this.configValidator,
    required this.packageScanner,
    required this.graphBuilder,
    required this.targetSelector,
    required this.commandPlanner,
    required this.clock,
    required this.logger,
    required this.pathService,
    required this.platform,
    required this.prompter,
    required this.versionInfo,
    required this.groupStoreFactory,
    required this.envBuilder,
    required this.plugins,
    required this.workspaceConfig,
    required this.taskExecutor,
    this.engine,
  });

  final CliParser parser;
  final ConfigLoader configLoader;
  final ConfigValidator configValidator;
  final PackageScanner packageScanner;
  final GraphBuilder graphBuilder;
  final TargetSelector targetSelector;
  final CommandPlanner commandPlanner;
  final Clock clock;
  final Logger logger;
  final PathService pathService;
  final PlatformInfo platform;
  final Prompter prompter;
  final VersionInfo versionInfo;
  final GroupStore Function(String monocfgPath) groupStoreFactory;
  final CommandEnvironmentBuilder envBuilder;
  final PluginResolver plugins;
  final WorkspaceConfig workspaceConfig;
  final TaskExecutor taskExecutor;
  final CliEngine? engine;
}

Future<int> runCli(List<String> argv, {CliWiring? wiring}) async {
  final parser = wiring?.parser ?? const ArgsCliParser();
  final prompter = wiring?.prompter ?? const ConsolePrompter();
  final versionInfo =
      wiring?.versionInfo ??
      const StaticVersionInfo(name: 'mono', version: 'unknown');
  final workspaceConfig =
      wiring?.workspaceConfig ?? const FileWorkspaceConfig();
  final logger = wiring?.logger ?? const StdLogger();

  final engine = wiring?.engine ?? const DefaultCliEngine();

  return engine.run(
    argv,
    parser: parser,
    logger: logger,
    routerFactory: () => DefaultCommandRouter(),
    helpText: () => _helpText,
    unknownCommandHelpHint: 'mono help',
    register: (router) {
      router.register('version', ({required inv, required logger}) async {
        return VersionCommand.run(
          inv: inv,
          logger: logger,
          version: versionInfo,
        );
      }, aliases: const ['--version', '-v', '--v']);

      router.register('setup', ({required inv, required logger}) async {
        return SetupCommand.run(
          inv: inv,
          logger: logger,
          workspaceConfig: workspaceConfig,
        );
      });

      router.register('scan', ({required inv, required logger}) async {
        return ScanCommand.run(
          inv: inv,
          logger: logger,
          workspaceConfig: workspaceConfig,
          packageScanner: wiring!.packageScanner,
        );
      });

      router.register('get', ({required inv, required logger}) async {
        return GetCommand.run(
          inv: inv,
          logger: logger,
          groupStoreFactory: wiring!.groupStoreFactory,
          envBuilder: wiring.envBuilder,
          plugins: wiring.plugins,
          executor: wiring.taskExecutor,
        );
      });

      router.register('format', ({required inv, required logger}) async {
        return FormatCommand.run(
          inv: inv,
          logger: logger,
          groupStoreFactory: wiring!.groupStoreFactory,
          envBuilder: wiring.envBuilder,
          plugins: wiring.plugins,
          executor: wiring.taskExecutor,
        );
      });

      router.register('test', ({required inv, required logger}) async {
        return TestCommand.run(
          inv: inv,
          logger: logger,
          groupStoreFactory: wiring!.groupStoreFactory,
          envBuilder: wiring.envBuilder,
          plugins: wiring.plugins,
          executor: wiring.taskExecutor,
        );
      });

      router.register('list', ({required inv, required logger}) async {
        return ListCommand.run(
          inv: inv,
          logger: logger,
          workspaceConfig: workspaceConfig,
          packageScanner: wiring!.packageScanner,
          groupStoreFactory: wiring.groupStoreFactory,
        );
      });

      router.register('tasks', ({required inv, required logger}) async {
        return TasksCommand.run(
          inv: inv,
          logger: logger,
          workspaceConfig: workspaceConfig,
        );
      });

      router.register('group', ({required inv, required logger}) async {
        return GroupCommand.run(
          inv: inv,
          logger: logger,
          prompter: prompter,
          workspaceConfig: workspaceConfig,
          packageScanner: wiring!.packageScanner,
          groupStoreFactory: wiring.groupStoreFactory,
        );
      });

      router.register('ungroup', ({required inv, required logger}) async {
        return UngroupCommand.run(
          inv: inv,
          logger: logger,
          prompter: prompter,
          workspaceConfig: workspaceConfig,
          groupStoreFactory: wiring!.groupStoreFactory,
        );
      });
    },
    fallback: ({required inv, required logger}) => TaskCommand.tryRun(
      inv: inv,
      logger: logger,
      groupStoreFactory: wiring!.groupStoreFactory,
      plugins: wiring.plugins,
      workspaceConfig: workspaceConfig,
      envBuilder: wiring.envBuilder,
      executor: wiring.taskExecutor,
    ),
  );
}

const String _helpText =
    'mono - Manage Dart/Flutter monorepos\n\n'
    'Usage:\n'
    '  mono setup\n'
    '  mono scan\n'
    '  mono get [targets]\n'
    '  mono format [targets] [--check]\n'
    '  mono test [targets]\n'
    '  mono [taskname] [targets]\n'
    '  mono list packages|groups|tasks\n'
    '  mono tasks\n'
    '  mono group <group_name>\n'
    '  mono ungroup <group_name>\n'
    '  mono version | -v | --version\n'
    '  mono help\n\n'
    'Notes:\n'
    '- Built-in commands like get run on all packages when no targets are given.\n'
    '- External tasks require explicit targets; use "all" to run on all packages.';
