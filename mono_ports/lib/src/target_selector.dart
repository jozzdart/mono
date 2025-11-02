import 'package:meta/meta.dart';
import 'package:mono_core_types/mono_core_types.dart';
import 'package:mono_selector_contracts/mono_selector_contracts.dart';
import 'package:mono_graph_contracts/mono_graph_contracts.dart';

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

