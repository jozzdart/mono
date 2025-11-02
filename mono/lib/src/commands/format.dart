import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

@immutable
class FormatCommand {
  static Future<int> run({
    required CliInvocation inv,
    required IOSink out,
    required IOSink err,
    required GroupStore Function(String monocfgPath) groupStoreFactory,
    required CommandEnvironmentBuilder envBuilder,
  }) async {
    final env =
        await envBuilder.build(inv, groupStoreFactory: groupStoreFactory);
    if (env.packages.isEmpty) {
      err.writeln('No packages found. Run `mono scan` first.');
      return 1;
    }

    final targets = env.selector.resolve(
      expressions: inv.targets,
      packages: env.packages,
      groups: env.groups,
      graph: env.graph,
      dependencyOrder: env.effectiveOrder,
    );
    if (targets.isEmpty) {
      err.writeln('No target packages matched.');
      return 1;
    }

    // Plan
    final planner = const DefaultCommandPlanner();
    final bool checkMode = inv.options['check']?.isNotEmpty == true;
    final task = TaskSpec(
      id: CommandId(checkMode ? 'format:check' : 'format'),
      plugin: const PluginId('format'),
    );
    final plan = planner.plan(task: task, targets: targets);

    // Plugins and runner
    final plugins = PluginRegistry({
      'pub': PubPlugin(),
      'exec': ExecPlugin(),
      'format': FormatPlugin(),
      'test': TestPlugin(),
    });

    final runner = Runner(
      processRunner: const DefaultProcessRunner(),
      logger: const StdLogger(),
      options: RunnerOptions(
        concurrency: env.effectiveConcurrency,
      ),
    );

    if (_isDryRun(inv)) {
      out.writeln(
        'Would run ${checkMode ? 'format:check' : 'format'} for ${targets.length} packages in ${env.effectiveOrder ? 'dependency' : 'input'} order.',
      );
      return 0;
    }

    return runner.execute(plan as SimpleExecutionPlan, plugins);
  }

  static bool _isDryRun(CliInvocation inv) =>
      inv.options['dry-run']?.isNotEmpty == true;
}
