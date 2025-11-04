import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

class FallbackCommand extends Command {
  const FallbackCommand();

  @override
  String get name => 'fallback';

  @override
  String get description => 'Fallback command';

  @override
  Future<int> run(CliContext context) => runCommand(
        unknownCommand: context.invocation.commandPath.join(' '),
        logger: context.logger,
        helpHint: context.router.getUnknownCommandHelpHint(),
      );

  static Future<int> runCommand({
    required String unknownCommand,
    required Logger logger,
    required String helpHint,
  }) async {
    logger.log('Unknown command: $unknownCommand', level: 'error');
    logger.log('Use `mono $helpHint`', level: 'error');
    return 1;
  }
}

class TaskCommand extends Command {
  @override
  String get description => 'Run a task by name';

  @override
  String get name => 'task';

  @override
  const TaskCommand();

  /// Attempts to run an arbitrary task by name as a top-level command.
  /// Returns fallback command if task is not defined.
  @override
  Future<int> run(CliContext ctx) async => runCommand(
        invocation: ctx.invocation,
        logger: ctx.logger,
        workspaceConfig: ctx.workspaceConfig,
        executor: ctx.executor,
        groupStore: await FileGroupStore.createFromContext(ctx),
        envBuilder: ctx.envBuilder,
        plugins: ctx.plugins,
        fallbackCommand: () => FallbackCommand().run(ctx),
      );

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

  static Future<int> runCommand({
    required CliInvocation invocation,
    required Logger logger,
    required WorkspaceConfig workspaceConfig,
    required TaskExecutor executor,
    required GroupStore groupStore,
    required CommandEnvironmentBuilder envBuilder,
    required PluginResolver plugins,
    required Future<int> Function() fallbackCommand,
  }) async {
    final inv = invocation;

    final taskName = inv.commandPath.first;

    // Load config and merged tasks
    final loaded = await workspaceConfig.loadRootConfig();
    final extra = await workspaceConfig.readMonocfgTasks(loaded.monocfgPath);
    final mergedTasks = <String, TaskDefinition>{
      ...loaded.config.tasks,
      ..._taskDefsFromExtra(extra),
    };
    final def = mergedTasks[taskName];
    if (def == null) return fallbackCommand();

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
    return await executor.execute(
      task: task,
      invocation: inv,
      logger: logger,
      groupStore: groupStore,
      envBuilder: envBuilder,
      plugins: plugins,
      env: def.env,
      dryRunLabel: taskName,
    );
  }
}
