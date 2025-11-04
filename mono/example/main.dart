import 'package:mono/mono_cli.dart';
import 'package:mono_cli/mono_cli.dart';

Future<void> main() async {
  final wiring = CliWiring(
    workspaceConfig: const FileWorkspaceConfig(),
    prompter: const ConsolePrompter(),
    parser: const ArgsCliParser(),
    configLoader: const YamlConfigLoader(),
    packageScanner: const FileSystemPackageScanner(),
    graphBuilder: const DefaultGraphBuilder(),
    targetSelector: const DefaultTargetSelector(),
    commandPlanner: const DefaultCommandPlanner(),
    clock: const SystemClock(),
    logger: const StdLogger(),
    pathService: const DefaultPathService(),
    envBuilder: const DefaultCommandEnvironmentBuilder(),
    plugins: PluginRegistry({}),
    taskExecutor: const DefaultTaskExecutor(),
    router: DefaultCommandRouter(
      commands: [],
      fallbackCommand: TasksCommand(),
      helpCommand: HelpCommand(),
    ),
  );
  final code = await runCli(['help'], wiring: wiring);
  print('mono exited with code $code');
}
