import 'package:mono_core/mono_core.dart';

void main() {
  final graph = DependencyGraph(
    nodes: {'a', 'b', 'c'},
    edges: {
      'b': {'a'},
      'c': {'b'},
    },
  );

  final order = graph.topologicalOrder();
  print('Build order: $order');

  try {
    final bad = DependencyGraph(
      nodes: {'x', 'y'},
      edges: {
        'x': {'y'},
        'y': {'x'},
      },
    );
    bad.topologicalOrder();
  } on GraphCycleError catch (e) {
    print('Cycle detected: ${e.cycle}');
  }
}


