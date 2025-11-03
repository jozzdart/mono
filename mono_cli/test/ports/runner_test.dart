import 'package:test/test.dart';
import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

import '../util/test_doubles.dart';

SimpleExecutionPlan planFor(List<MonoPackage> pkgs, TaskSpec task) =>
    SimpleExecutionPlan([
      for (final p in pkgs) PlanStep(package: p, task: task),
    ]);

void main() {
  group('Runner', () {
    test('returns 127 and logs when plugin missing', () async {
      final logger = RecordingLogger();
      final runner = Runner(processRunner: StubProcessRunner(), logger: logger);
      final task =
          TaskSpec(id: const CommandId('do'), plugin: const PluginId('nope'));
      final plan = planFor([pkg('a')], task);
      final registry = PluginRegistry(<String, TaskPlugin>{});
      final code = await runner.execute(plan, registry);
      expect(code, 1); // aggregate sees a non-zero (127)
      expect(logger.byLevel('error').map((e) => e.message).join(' '),
          contains('No plugin for do'));
    });

    test('returns 127 and logs when plugin does not support command', () async {
      final logger = RecordingLogger();
      final runner = Runner(processRunner: StubProcessRunner(), logger: logger);
      final task =
          TaskSpec(id: const CommandId('cmd'), plugin: const PluginId('p'));
      final plan = planFor([pkg('b')], task);
      final notSupporting = TestTaskPlugin('p', supports: (_) => false);
      final registry = PluginRegistry({'p': notSupporting});
      final code = await runner.execute(plan, registry);
      expect(code, 1);
      expect(logger.byLevel('error').map((e) => e.message).join(' '),
          contains('No plugin for cmd'));
    });

    test('runs all steps, aggregates non-zero to 1, logs status', () async {
      final logger = RecordingLogger();
      final codes = <int>[0, 2, 0];
      final plugins = <String, TaskPlugin>{
        'ok': TestTaskPlugin('ok', onExecute: (_) async => codes.removeAt(0)),
      };
      final registry = PluginRegistry(plugins);
      final runner = Runner(
        processRunner: StubProcessRunner(),
        logger: logger,
        options: const RunnerOptions(concurrency: 2),
      );
      final task =
          TaskSpec(id: const CommandId('run'), plugin: const PluginId('ok'));
      final plan = planFor([pkg('p1'), pkg('p2'), pkg('p3')], task);
      final code = await runner.execute(plan, registry);
      expect(code, 1);
      final infoLogs = logger.byLevel('info').map((e) => e.message).toList();
      expect(infoLogs.where((m) => m.startsWith('Running')).length, 3);
      expect(
          infoLogs.where((m) => m == 'Done').length, greaterThanOrEqualTo(2));
      final errorLogs = logger.byLevel('error').map((e) => e.message).join(' ');
      expect(errorLogs, contains('Failed with exit code 2'));
    });

    test('passes env from options to plugin execute', () async {
      final invocations = <TaskInvocation>[];
      final plugin = TestTaskPlugin('pp', onExecute: (i) async {
        invocations.add(i);
        return 0;
      });
      final registry = PluginRegistry({'pp': plugin});
      final runner = Runner(
        processRunner: StubProcessRunner(),
        logger: RecordingLogger(),
        options: const RunnerOptions(env: {'K': 'V'}),
      );
      final task =
          TaskSpec(id: const CommandId('id'), plugin: const PluginId('pp'));
      final plan = planFor([pkg('q')], task);
      final code = await runner.execute(plan, registry);
      expect(code, 0);
      expect(invocations, hasLength(1));
      expect(invocations.single.env, containsPair('K', 'V'));
    });
  });
}
