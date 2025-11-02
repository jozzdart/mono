import 'package:mono_cli/mono_cli.dart';

class TaskCommand {
  /// Attempts to run an arbitrary task by name as a top-level command.
  /// Returns null if task is not defined.
  static Future<int?> tryRun({
    required CliInvocation inv,
    required Logger logger,
    required GroupStore Function(String monocfgPath) groupStoreFactory,
    required PluginResolver plugins,
    required WorkspaceConfig workspaceConfig,
    required CommandEnvironmentBuilder envBuilder,
    required TaskExecutor executor,
  }) async {
    final taskName = inv.commandPath.first;
    // Load config and merged tasks
    final loaded = await workspaceConfig.loadRootConfig();
    final extra = await workspaceConfig.readMonocfgTasks(loaded.monocfgPath);
    final mergedTasks = <String, TaskDefinition>{
      ...loaded.config.tasks,
      ..._taskDefsFromExtra(extra),
    };
    final def = mergedTasks[taskName];
    if (def == null) return null; // Not a task name

    // Determine plugin and validate target requirement for external tasks
    final pluginId = PluginId(def.plugin ?? 'exec');
    if (pluginId.value == 'exec' && inv.targets.isEmpty) {
      logger.log(
          'External tasks require explicit targets. Use "all" to run on all packages.',
          level: 'error');
      return 2;
    }

    // Build TaskSpec from definition
    final CommandId commandId;
    if (pluginId.value == 'exec') {
      if (def.run.isEmpty || def.run.first.trim().isEmpty) {
        logger.log('Task "$taskName" has no run command.', level: 'error');
        return 1;
      }
      // Execute only the first run entry for now
      commandId = CommandId('exec:${def.run.first.trim()}');
    } else if (pluginId.value == 'pub') {
      final name = taskName.trim();
      if (name == 'get') {
        commandId = const CommandId('get');
      } else if (name == 'clean') {
        commandId = const CommandId('clean');
      } else {
        logger.log('Unsupported pub task: $name', level: 'error');
        return 1;
      }
    } else if (pluginId.value == 'format') {
      final check = inv.options['check']?.isNotEmpty == true;
      commandId = CommandId(check ? 'format:check' : 'format');
    } else if (pluginId.value == 'test') {
      commandId = const CommandId('test');
    } else {
      logger.log('Unknown plugin for task "$taskName": ${pluginId.value}',
          level: 'error');
      return 1;
    }
    // Additional policy: external tasks require explicit targets
    if (pluginId.value == 'exec' && inv.targets.isEmpty) {
      logger.log(
          'External tasks require explicit targets. Use "all" to run on all packages.',
          level: 'error');
      return 2;
    }

    final task = TaskSpec(id: commandId, plugin: pluginId);
    return executor.execute(
      task: task,
      inv: inv,
      logger: logger,
      groupStoreFactory: groupStoreFactory,
      envBuilder: envBuilder,
      plugins: plugins,
      env: def.env,
      dryRunLabel: taskName,
    );
  }

  static Map<String, TaskDefinition> _taskDefsFromExtra(
      Map<String, Map<String, Object?>> extra) {
    List<String> strList(Object? v) {
      if (v is List) return v.map((e) => '$e').toList();
      return const <String>[];
    }

    Map<String, String> mapSS(Object? v) {
      if (v is Map) {
        return {for (final e in v.entries) '${e.key}': '${e.value}'};
      }
      return const <String, String>{};
    }

    final out = <String, TaskDefinition>{};
    for (final e in extra.entries) {
      final m = e.value;
      final def = TaskDefinition(
        plugin: m['plugin']?.toString(),
        dependsOn: strList(m['dependsOn']),
        env: mapSS(m['env']),
        run: strList(m['run']),
      );
      out[e.key] = def;
    }
    return out;
  }
}
