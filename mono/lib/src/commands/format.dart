import 'package:mono_core/mono_core.dart';

@immutable
class FormatCommand {
  static Future<int> run({
    required CliInvocation inv,
    required Logger logger,
    required GroupStore Function(String monocfgPath) groupStoreFactory,
    required CommandEnvironmentBuilder envBuilder,
    required PluginResolver plugins,
    required TaskExecutor executor,
  }) async {
    final bool checkMode = inv.options['check']?.isNotEmpty == true;
    final task = TaskSpec(
      id: CommandId(checkMode ? 'format:check' : 'format'),
      plugin: const PluginId('format'),
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
