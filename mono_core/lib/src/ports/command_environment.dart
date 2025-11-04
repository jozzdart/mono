import 'package:mono_core/mono_core.dart';

/// Immutable environment describing the execution context for a CLI command.
class CommandEnvironment {
  const CommandEnvironment({
    required this.config,
    required this.monocfgPath,
    required this.packages,
    required this.graph,
    required this.groups,
    required this.selector,
    required this.effectiveOrder,
    required this.effectiveConcurrency,
  });

  final MonoConfig config;
  final String monocfgPath;
  final List<MonoPackage> packages;
  final DependencyGraph graph;
  final Map<String, Set<String>> groups;
  final TargetSelector selector;
  final bool effectiveOrder; // true => dependency order
  final int effectiveConcurrency;
}

/// Builder interface to construct a [CommandEnvironment] from a CLI invocation.
abstract class CommandEnvironmentBuilder {
  const CommandEnvironmentBuilder();

  Future<CommandEnvironment> build(
    CliInvocation inv, {
    required GroupStore groupStore,
  });
}
