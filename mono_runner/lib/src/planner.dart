import 'package:meta/meta.dart';
import 'package:mono_core_types/mono_core_types.dart';
import 'package:mono_ports/mono_ports.dart';

@immutable
class PlanStep {
  const PlanStep({required this.package, required this.task});
  final MonoPackage package;
  final TaskSpec task;
}

@immutable
class SimpleExecutionPlan extends ExecutionPlan {
  const SimpleExecutionPlan(this.steps);
  final List<PlanStep> steps;
}

@immutable
class DefaultCommandPlanner implements CommandPlanner {
  const DefaultCommandPlanner();

  @override
  ExecutionPlan plan({required TaskSpec task, required List<MonoPackage> targets}) {
    final steps = [for (final p in targets) PlanStep(package: p, task: task)];
    return SimpleExecutionPlan(steps);
  }
}


