import 'package:mono_cli/mono_cli.dart';

class GetCommand {
  static Future<int> run(
      {required CliInvocation inv,
      required Logger logger,
      required GroupStore Function(String monocfgPath) groupStoreFactory,
      required CommandEnvironmentBuilder envBuilder,
      required PluginResolver plugins,
      required TaskExecutor executor}) async {
    final task = TaskSpec(
      id: const CommandId('get'),
      plugin: const PluginId('pub'),
    );
    return executor.execute(
      task: task,
      inv: inv,
      logger: logger,
      groupStoreFactory: groupStoreFactory,
      envBuilder: envBuilder,
      plugins: plugins,
    );
  }
}
