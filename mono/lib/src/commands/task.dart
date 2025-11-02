import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

import '../config_io.dart';

class TaskCommand {
  /// Attempts to run an arbitrary task by name as a top-level command.
  /// Returns null if task is not defined.
  static Future<int?> tryRun({
    required CliInvocation inv,
    required IOSink out,
    required IOSink err,
    required GroupStore Function(String monocfgPath) groupStoreFactory,
  }) async {
    final taskName = inv.commandPath.first;
    // Load config and merged tasks
    final loaded = await loadRootConfig();
    final extra = await readMonocfgTasks(loaded.monocfgPath);
    final mergedTasks = <String, TaskDefinition>{
      ...loaded.config.tasks,
      ..._taskDefsFromExtra(extra),
    };
    final def = mergedTasks[taskName];
    if (def == null) return null; // Not a task name

    // Determine plugin and validate target requirement for external tasks
    final pluginId = PluginId(def.plugin ?? 'exec');
    if (pluginId.value == 'exec' && inv.targets.isEmpty) {
      err.writeln(
          'External tasks require explicit targets. Use "all" to run on all packages.');
      return 2;
    }

    // Build package list
    final root = Directory.current.path;
    final scanner = const FileSystemPackageScanner();
    final packages = await scanner.scan(
      rootPath: root,
      includeGlobs: loaded.config.include,
      excludeGlobs: loaded.config.exclude,
    );
    if (packages.isEmpty) {
      err.writeln('No packages found. Run `mono scan` first.');
      return 1;
    }

    // Build graph and resolve targets
    final graph = const DefaultGraphBuilder().build(packages);

    final store = groupStoreFactory(loaded.monocfgPath);
    final groups = <String, Set<String>>{};
    final groupNames = await store.listGroups();
    for (final name in groupNames) {
      final members = await store.readGroup(name);
      groups[name] = members.toSet();
    }

    final selector = const DefaultTargetSelector();
    final dependencyOrder = _effectiveOrder(inv, loaded.config) == 'dependency';
    final targets = selector.resolve(
      expressions: inv.targets,
      packages: packages,
      groups: groups,
      graph: graph,
      dependencyOrder: dependencyOrder,
    );

    if (targets.isEmpty) {
      err.writeln('No target packages matched.');
      return 1;
    }

    // Build TaskSpec from definition
    final CommandId commandId;
    if (pluginId.value == 'exec') {
      if (def.run.isEmpty || def.run.first.trim().isEmpty) {
        err.writeln('Task "$taskName" has no run command.');
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
        err.writeln('Unsupported pub task: $name');
        return 1;
      }
    } else {
      err.writeln('Unknown plugin for task "$taskName": ${pluginId.value}');
      return 1;
    }

    final planner = const DefaultCommandPlanner();
    final task = TaskSpec(id: commandId, plugin: pluginId);
    final plan = planner.plan(task: task, targets: targets);

    final plugins = PluginRegistry({
      'pub': PubPlugin(),
      'exec': ExecPlugin(),
    });

    final runner = Runner(
      processRunner: const DefaultProcessRunner(),
      logger: const StdLogger(),
      options: RunnerOptions(
        concurrency: _effectiveConcurrency(inv, loaded.config),
        env: def.env,
      ),
    );

    if (_isDryRun(inv)) {
      out.writeln(
          'Would run $taskName for ${targets.length} packages in ${dependencyOrder ? 'dependency' : 'input'} order.');
      return 0;
    }

    return runner.execute(plan as SimpleExecutionPlan, plugins);
  }

  static String _effectiveOrder(CliInvocation inv, MonoConfig cfg) {
    final list = inv.options['order'];
    final fromCli = (list != null && list.isNotEmpty) ? list.first : null;
    return fromCli ?? cfg.settings.defaultOrder;
  }

  static int _effectiveConcurrency(CliInvocation inv, MonoConfig cfg) {
    final list = inv.options['concurrency'];
    final fromCli = (list != null && list.isNotEmpty) ? list.first : null;
    final str = fromCli ?? cfg.settings.concurrency;
    final n = int.tryParse(str);
    if (n != null && n > 0) return n;
    try {
      return Platform.numberOfProcessors.clamp(1, 8);
    } catch (_) {
      return 4;
    }
  }

  static bool _isDryRun(CliInvocation inv) =>
      inv.options['dry-run']?.isNotEmpty == true;

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
