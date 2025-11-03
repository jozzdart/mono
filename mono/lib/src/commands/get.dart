import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

class GetCommand extends Command {
  const GetCommand();

  @override
  String get name => 'get';

  @override
  String get description => 'Run pub get across targets (Dart/Flutter)';

  @override
  Future<int> run(
    CliContext context,
  ) async =>
      await runCommand(
        invocation: context.invocation,
        logger: context.logger,
        groupStore: await FileGroupStore.createFromContext(context),
        envBuilder: context.envBuilder,
        plugins: context.plugins,
        executor: context.executor,
      );

  static Future<int> runCommand({
    required CliInvocation invocation,
    required Logger logger,
    required GroupStore groupStore,
    required CommandEnvironmentBuilder envBuilder,
    required PluginResolver plugins,
    required TaskExecutor executor,
  }) async {
    final task = TaskSpec(
      id: const CommandId('get'),
      plugin: const PluginId('pub'),
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
