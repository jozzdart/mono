import 'dart:async';

import 'package:mono_cli/mono_cli.dart';

@immutable
class RunnerOptions {
  const RunnerOptions({this.concurrency = 1, this.env = const {}});
  final int concurrency;
  final Map<String, String> env;
}

class Runner {
  Runner(
      {required this.processRunner,
      required this.logger,
      this.options = const RunnerOptions()});
  final ProcessRunner processRunner;
  final Logger logger;
  final RunnerOptions options;

  Future<int> execute(SimpleExecutionPlan plan, PluginRegistry plugins) async {
    final pool = Pool(options.concurrency <= 0 ? 1 : options.concurrency);
    final results = <Future<int>>[];
    for (final step in plan.steps) {
      results.add(pool.withResource(() async {
        final plugin = plugins.resolve(step.task.plugin);
        if (plugin == null || !plugin.supports(step.task.id)) {
          logger.log(
              'No plugin for ${step.task.id} (plugin: ${step.task.plugin?.value ?? 'none'})',
              scope: step.package.name.value,
              level: 'error');
          return 127;
        }
        logger.log('Running ${step.task.id.value}',
            scope: step.package.name.value, level: 'info');
        final code = await plugin.execute(
          commandId: step.task.id,
          package: step.package,
          processRunner: processRunner,
          logger: logger,
          env: options.env,
        );
        if (code != 0) {
          logger.log('Failed with exit code $code',
              scope: step.package.name.value, level: 'error');
        } else {
          logger.log('Done', scope: step.package.name.value, level: 'info');
        }
        return code;
      }));
    }
    final codes = await Future.wait(results);
    await pool.close();
    return codes.any((c) => c != 0) ? 1 : 0;
  }
}
