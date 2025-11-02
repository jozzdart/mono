import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

void main() {
  group('DependencyGraph', () {
    test('topological order for simple DAG', () {
      final g = DependencyGraph(
        nodes: {'a', 'b', 'c'},
        edges: {
          'a': {'b'},
          'b': {'c'},
          'c': <String>{},
        },
      );
      final order = g.topologicalOrder();
      // order should have c before b before a
      expect(order.indexOf('c') < order.indexOf('b'), isTrue);
      expect(order.indexOf('b') < order.indexOf('a'), isTrue);
    });

    test('detects cycles', () {
      final g = DependencyGraph(
        nodes: {'a', 'b'},
        edges: {
          'a': {'b'},
          'b': {'a'},
        },
      );
      expect(() => g.topologicalOrder(), throwsA(isA<GraphCycleError>()));
    });
  });
}

