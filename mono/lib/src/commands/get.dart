import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

class GetCommand {
  static Future<int> run(
      {required CliInvocation inv,
      required IOSink out,
      required IOSink err,
      required GroupStore Function(String monocfgPath) groupStoreFactory,
      required CommandEnvironmentBuilder envBuilder}) async {
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
      options: RunnerOptions(concurrency: env.effectiveConcurrency),
    );

    if (_isDryRun(inv)) {
      out.writeln(
          'Would run get for ${targets.length} packages in ${env.effectiveOrder ? 'dependency' : 'input'} order.');
      return 0;
    }

    return runner.execute(plan as SimpleExecutionPlan, plugins);
  }

  static bool _isDryRun(CliInvocation inv) =>
      inv.options['dry-run']?.isNotEmpty == true;
}
