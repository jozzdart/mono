import 'package:mono_core/mono_core.dart';

class TasksCommand extends Command {
  const TasksCommand();

  @override
  String get name => 'tasks';

  @override
  String get description =>
      'List merged tasks (mono.yaml + monocfg/tasks.yaml)';

  @override
  Future<int> run(
    CliContext context,
  ) =>
      runCommand(
        logger: context.logger,
        workspaceConfig: context.workspaceConfig,
      );

  static Future<int> runCommand({
    required Logger logger,
    required WorkspaceConfig workspaceConfig,
  }) async {
    final loaded = await workspaceConfig.loadRootConfig();
    final merged = <String, Map<String, Object?>>{};
    for (final e in loaded.config.tasks.entries) {
      merged[e.key] = {
        if (e.value.plugin != null) 'plugin': e.value.plugin,
        if (e.value.dependsOn.isNotEmpty) 'dependsOn': e.value.dependsOn,
        if (e.value.env.isNotEmpty) 'env': e.value.env,
        if (e.value.run.isNotEmpty) 'run': e.value.run,
      };
    }
    final extra = await workspaceConfig.readMonocfgTasks(loaded.monocfgPath);
    merged.addAll(extra);
    for (final e in merged.entries) {
      final plugin = (e.value['plugin'] ?? 'exec').toString();
      logger.log('- ${e.key} (plugin: $plugin)');
    }
    return 0;
  }
}
