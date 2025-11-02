import 'package:meta/meta.dart';
import 'package:mono_core_types/mono_core_types.dart';

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

