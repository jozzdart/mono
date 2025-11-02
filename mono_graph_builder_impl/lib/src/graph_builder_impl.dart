import 'package:meta/meta.dart';
import 'package:mono_core_types/mono_core_types.dart';
import 'package:mono_graph_contracts/mono_graph_contracts.dart';
import 'package:mono_ports/mono_ports.dart';

@immutable
class DefaultGraphBuilder implements GraphBuilder {
  const DefaultGraphBuilder();

  @override
  DependencyGraph build(List<MonoPackage> packages) {
    final nodes = <String>{for (final p in packages) p.name.value};
    final edges = <String, Set<String>>{};
    for (final p in packages) {
      edges[p.name.value] = {
        for (final d in p.localDependencies) if (nodes.contains(d.value)) d.value,
      };
    }
    return DependencyGraph(nodes: nodes, edges: edges);
  }
}


