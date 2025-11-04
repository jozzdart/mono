import 'package:mono/src/cli.dart';
import 'package:mono/src/commands/help.dart';
import 'package:mono/src/commands/task.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

class FakeWiring extends CliWiring {
  FakeWiring({Logger? logger, CommandRouter? router})
      : super(
          parser: ArgsCliParser(),
          configLoader: YamlConfigLoader(),
          packageScanner: FileSystemPackageScanner(),
          graphBuilder: DefaultGraphBuilder(),
          targetSelector: DefaultTargetSelector(),
          commandPlanner: const DefaultCommandPlanner(),
          clock: const SystemClock(),
          logger: logger ?? const StdLogger(),
          pathService: const DefaultPathService(),
          prompter: const ConsolePrompter(),
          envBuilder: const DefaultCommandEnvironmentBuilder(),
          plugins: PluginRegistry({}),
          workspaceConfig: const FileWorkspaceConfig(),
          taskExecutor: const DefaultTaskExecutor(),
          router: router ??
              DefaultCommandRouter(
                commands: [],
                fallbackCommand: const FallbackCommand(),
                helpCommand: const HelpCommand(),
              ),
        );
}
