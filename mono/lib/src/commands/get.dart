import 'dart:io';

import 'package:meta/meta.dart';
import 'package:mono_cli_shared_contracts/mono_cli_shared_contracts.dart';
import 'package:mono_core_types/mono_core_types.dart';

import 'package:mono_runner/mono_runner.dart';
import 'package:mono_scanner_fs/mono_scanner_fs.dart';
import 'package:mono_graph_builder_impl/mono_graph_builder_impl.dart';
import 'package:mono_selector_impl/mono_selector_impl.dart';
import 'package:mono_plugin_pub/mono_plugin_pub.dart';
import 'package:mono_plugin_exec/mono_plugin_exec.dart';
import 'package:mono_system_io/mono_system_io.dart';

import 'package:mono_config_contracts/mono_config_contracts.dart';
import '../config_io.dart';

@immutable
class GetOptions {
  const GetOptions(
      {this.concurrency, this.order = 'dependency', this.dryRun = false});
  final int? concurrency;
  final String order; // 'dependency' | 'none'
  final bool dryRun;
}

class GetCommand {
  static Future<int> run(
      {required CliInvocation inv,
      required IOSink out,
      required IOSink err}) async {
    final loaded = await loadRootConfig();
    final root = Directory.current.path;

    // Scanner for accurate graph deps
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

    final groups = <String, Set<String>>{
      for (final e in loaded.config.groups.entries) e.key: e.value.toSet(),
    };

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

    // Plan and run
    final planner = const DefaultCommandPlanner();
    final task =
        TaskSpec(id: const CommandId('get'), plugin: const PluginId('pub'));
    final plan = planner.plan(task: task, targets: targets);

    final plugins = PluginRegistry({
      'pub': PubPlugin(),
      'exec': ExecPlugin(),
    });

    final runner = Runner(
      processRunner: const DefaultProcessRunner(),
      logger: const StdLogger(),
      options:
          RunnerOptions(concurrency: _effectiveConcurrency(inv, loaded.config)),
    );

    if (_isDryRun(inv)) {
      out.writeln(
          'Would run get for ${targets.length} packages in ${dependencyOrder ? 'dependency' : 'input'} order.');
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
    // simple auto heuristic
    try {
      return Platform.numberOfProcessors.clamp(1, 8);
    } catch (_) {
      return 4;
    }
  }

  static bool _isDryRun(CliInvocation inv) =>
      inv.options['dry-run']?.isNotEmpty == true;
}
