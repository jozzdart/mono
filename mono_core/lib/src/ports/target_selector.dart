import 'package:mono_core/mono_core.dart';

@immutable
abstract class TargetSelector {
  const TargetSelector();
  List<MonoPackage> resolve({
    required List<TargetExpr> expressions,
    required List<MonoPackage> packages,
    required Map<String, Set<String>> groups, // groupName -> package names
    required DependencyGraph graph,
    required bool dependencyOrder, // true => topo order, else keep input order
  });
}
