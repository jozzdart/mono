import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

class DefaultTaskExecutor implements TaskExecutor {
  const DefaultTaskExecutor({
    this.processRunner = const DefaultProcessRunner(),
    this.commandPlanner = const DefaultCommandPlanner(),
  });
  final ProcessRunner processRunner;
  final CommandPlanner commandPlanner;

  @override
  Future<int> execute({
    required TaskSpec task,
    required CliInvocation inv,
    required Logger logger,
    required GroupStore Function(String) groupStoreFactory,
    required CommandEnvironmentBuilder envBuilder,
    required PluginResolver plugins,
    Map<String, String> env = const {},
    String? dryRunLabel,
  }) async {
    final envCtx =
        await envBuilder.build(inv, groupStoreFactory: groupStoreFactory);

    if (envCtx.packages.isEmpty) {
      logger.log('No packages found. Run `mono scan` first.', level: 'error');
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
      logger.log('No target packages matched.', level: 'error');
      return 1;
    }

    final plan = commandPlanner.plan(task: task, targets: targets)
        as SimpleExecutionPlan;

    if (inv.options['dry-run']?.isNotEmpty == true) {
      final label =
          dryRunLabel?.trim().isNotEmpty == true ? dryRunLabel! : task.id.value;
      logger.log(
          'Would run $label for ${targets.length} packages in ${envCtx.effectiveOrder ? 'dependency' : 'input'} order.');
      return 0;
    }

    final runner = Runner(
      processRunner: processRunner,
      logger: logger,
      options: RunnerOptions(
        concurrency: envCtx.effectiveConcurrency,
        env: env,
      ),
    );

    return runner.execute(plan, plugins);
  }
}
