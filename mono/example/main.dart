import 'package:mono/src/cli.dart';
import 'package:mono_cli/mono_cli.dart';

Future<void> main() async {
  final wiring = CliWiring(
    workspaceConfig: const FileWorkspaceConfig(),
    prompter: const ConsolePrompter(),
    parser: const ArgsCliParser(),
    configLoader: const YamlConfigLoader(),
    configValidator: const YamlConfigValidator(),
    packageScanner: const FileSystemPackageScanner(),
    graphBuilder: const DefaultGraphBuilder(),
    targetSelector: const DefaultTargetSelector(),
    commandPlanner: const DefaultCommandPlanner(),
    clock: const SystemClock(),
    logger: const StdLogger(),
    pathService: const DefaultPathService(),
    platform: const DefaultPlatformInfo(),
    versionInfo: const StaticVersionInfo(name: 'mono', version: 'example'),
    envBuilder: const DefaultCommandEnvironmentBuilder(),
    plugins: PluginRegistry({}),
    taskExecutor: const DefaultTaskExecutor(),
    groupStoreFactory: (String monocfgPath) => FileGroupStore(
      FileListConfigFolder(basePath: '$monocfgPath/groups'),
    ),
  );
  final code = await runCli(['help'], wiring: wiring);
  print('mono exited with code $code');
}
