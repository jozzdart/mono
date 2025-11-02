import 'package:meta/meta.dart';
import 'package:mono_core_types/mono_core_types.dart';
import 'package:mono_graph_contracts/mono_graph_contracts.dart';

@immutable
abstract class GraphBuilder {
  const GraphBuilder();
  DependencyGraph build(List<MonoPackage> packages);
}

