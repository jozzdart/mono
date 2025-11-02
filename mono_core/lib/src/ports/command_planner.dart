import 'package:mono_core/mono_core.dart';

@immutable
abstract class ExecutionPlan {
  const ExecutionPlan();
}

@immutable
abstract class CommandPlanner {
  const CommandPlanner();
  ExecutionPlan plan({
    required TaskSpec task,
    required List<MonoPackage> targets,
  });
}
