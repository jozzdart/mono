import 'dart:io';

import 'package:mono_cli/mono_cli.dart';

class DefaultTaskExecutor implements TaskExecutor {
  const DefaultTaskExecutor();

  @override
  Future<int> execute({
    required TaskSpec task,
    required CliInvocation inv,
    required IOSink out,
    required IOSink err,
    required GroupStore Function(String) groupStoreFactory,
    required CommandEnvironmentBuilder envBuilder,
    required PluginResolver plugins,
    Map<String, String> env = const {},
    String? dryRunLabel,
  }) async {
    final envCtx =
        await envBuilder.build(inv, groupStoreFactory: groupStoreFactory);

    if (envCtx.packages.isEmpty) {
      err.writeln('No packages found. Run `mono scan` first.');
      return 1;
    }

    final targets = envCtx.selector.resolve(
      expressions: inv.targets,
      packages: envCtx.packages,
      groups: envCtx.groups,
      graph: envCtx.graph,
      dependencyOrder: envCtx.effectiveOrder,
    );

    if (targets.isEmpty) {
      err.writeln('No target packages matched.');
      return 1;
    }

    final plan = const DefaultCommandPlanner()
        .plan(task: task, targets: targets) as SimpleExecutionPlan;

    if (inv.options['dry-run']?.isNotEmpty == true) {
      final label =
          dryRunLabel?.trim().isNotEmpty == true ? dryRunLabel! : task.id.value;
      out.writeln(
          'Would run $label for ${targets.length} packages in ${envCtx.effectiveOrder ? 'dependency' : 'input'} order.');
      return 0;
    }

    final runner = Runner(
      processRunner: const DefaultProcessRunner(),
      logger: const StdLogger(),
      options: RunnerOptions(
        concurrency: envCtx.effectiveConcurrency,
        env: env,
      ),
    );

    return runner.execute(plan, plugins);
  }
}
