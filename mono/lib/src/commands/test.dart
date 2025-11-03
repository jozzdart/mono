import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

class TestCommand extends Command {
  const TestCommand();

  @override
  String get name => 'test';

  @override
  String get description => 'Run tests across targets';

  @override
  Future<int> run(
    CliContext context,
  ) async =>
      await runCommand(
        invocation: context.invocation,
        logger: context.logger,
        workspaceConfig: context.workspaceConfig,
        executor: context.executor,
        envBuilder: context.envBuilder,
        plugins: context.plugins,
        groupStore: await FileGroupStore.createFromContext(context),
      );

  static Future<int> runCommand({
    required CliInvocation invocation,
    required Logger logger,
    required WorkspaceConfig workspaceConfig,
    required TaskExecutor executor,
    required CommandEnvironmentBuilder envBuilder,
    required PluginResolver plugins,
    required GroupStore groupStore,
  }) async {
    final task = TaskSpec(
      id: const CommandId('test'),
      plugin: const PluginId('test'),
    );

    return await executor.execute(
      task: task,
      invocation: invocation,
      logger: logger,
      groupStore: groupStore,
      envBuilder: envBuilder,
      plugins: plugins,
    );
  }
}
