import 'package:test/test.dart';
import 'package:mono_cli/mono_cli.dart';

import '../util/test_doubles.dart';

void main() {
  group('DefaultCommandPlanner', () {
    test('creates one step per target preserving order and task', () {
      final planner = const DefaultCommandPlanner();
      final task =
          TaskSpec(id: CommandId('format'), plugin: const PluginId('format'));
      final targets = [pkg('a'), pkg('b'), pkg('c')];
      final plan =
          planner.plan(task: task, targets: targets) as SimpleExecutionPlan;
      expect(plan.steps.map((s) => s.package.name.value).toList(),
          ['a', 'b', 'c']);
      expect(plan.steps.map((s) => s.task).every((t) => t == task), isTrue);
    });
  });
}
