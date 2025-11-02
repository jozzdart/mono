import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

void main() {
  group('DependencyGraph - construction and immutability', () {
    test('nodes and edges are unmodifiable views', () {
      final g = DependencyGraph(
        nodes: {'a', 'b'},
        edges: {
          'a': {'b'},
          'b': <String>{},
        },
      );

      expect(() => g.nodes.add('c'), throwsUnsupportedError);
      expect(() => g.edges['a'] = {'x'}, throwsUnsupportedError);
      expect(() => g.edges['a']!.add('x'), throwsUnsupportedError);
      expect(() => g.edges['b']!.add('x'), throwsUnsupportedError);

      // dependenciesOf returns an unmodifiable set
      expect(() => g.dependenciesOf('a').add('x'), throwsUnsupportedError);
      expect(
          () => g.dependenciesOf('missing').add('x'), throwsUnsupportedError);
    });

    test('defensive copies prevent external mutation from affecting graph', () {
      final nodes = {'a', 'b'};
      final depsA = {'b'};
      final edges = {
        'a': depsA,
        'b': <String>{},
      };

      final g = DependencyGraph(nodes: nodes, edges: edges);

      // mutate original inputs
      nodes.add('c');
      depsA.add('x');
      edges['a'] = {'x'};

      // graph remains unchanged
      expect(g.nodes, {'a', 'b'});
      expect(g.edges['a'], {'b'});
      expect(g.edges.containsKey('c'), isFalse);
    });
  });

  group('DependencyGraph - dependenciesOf', () {
    test('returns dependencies for known node and empty set for unknown', () {
      final g = DependencyGraph(
        nodes: {'a', 'b', 'c'},
        edges: {
          'a': {'b', 'c'},
          'b': <String>{},
          'c': <String>{},
        },
      );

      expect(g.dependenciesOf('a'), containsAll(<String>['b', 'c']));
      expect(g.dependenciesOf('b'), isEmpty);
      expect(g.dependenciesOf('missing'), isEmpty);
    });
  });

  group('DependencyGraph - topologicalOrder (validity property)', () {
    List<String> topo(DependencyGraph g) => g.topologicalOrder();

    void expectTopoValid(DependencyGraph g, List<String> order) {
      // Build index map
      final index = <String, int>{};
      for (var i = 0; i < order.length; i++) {
        index[order[i]] = i;
      }

      // All nodes must appear exactly once
      expect(order.toSet(), g.nodes);
      expect(order.length, g.nodes.length);

      // For each edge u -> v (u depends on v per current model),
      // the algorithm returns u before v.
      for (final entry in g.edges.entries) {
        final u = entry.key;
        for (final v in entry.value) {
          if (!g.nodes.contains(v)) continue; // ignore edges to unknown nodes
          expect(index[u]!, lessThan(index[v]!));
        }
      }
    }

    test('empty graph', () {
      final g = DependencyGraph(nodes: <String>{}, edges: const {});
      final order = topo(g);
      expect(order, isEmpty);
    });

    test('single node with no edges', () {
      final g = DependencyGraph(nodes: {'a'}, edges: const {});
      expect(topo(g), ['a']);
    });

    test('simple chain a -> b -> c (a before b before c)', () {
      final g = DependencyGraph(
        nodes: {'a', 'b', 'c'},
        edges: {
          'a': {'b'},
          'b': {'c'},
          'c': <String>{},
        },
      );

      final order = topo(g);
      expectTopoValid(g, order);
      // Stricter check for the chain
      expect(order, equals(['a', 'b', 'c']));
    });

    test('diamond graph: a -> {b, c}, {b, c} -> d', () {
      final g = DependencyGraph(
        nodes: {'a', 'b', 'c', 'd'},
        edges: {
          'a': {'b', 'c'},
          'b': {'d'},
          'c': {'d'},
          'd': <String>{},
        },
      );

      final order = topo(g);
      expectTopoValid(g, order);
      // a must come before b and c; d must come last
      final i = {for (var i = 0; i < order.length; i++) order[i]: i};
      expect(i['a']!, lessThan(i['b']!));
      expect(i['a']!, lessThan(i['c']!));
      expect(i['b']!, lessThan(i['d']!));
      expect(i['c']!, lessThan(i['d']!));
    });

    test('disconnected subgraphs are all included', () {
      final g = DependencyGraph(
        nodes: {'a', 'b', 'c', 'x', 'y'},
        edges: {
          'a': {'b'},
          'b': {'c'},
          'c': <String>{},
          'x': {'y'},
          'y': <String>{},
        },
      );
      final order = topo(g);
      expectTopoValid(g, order);
    });

    test('large chain remains valid and complete', () {
      const n = 200;
      final nodes = {for (var i = 0; i < n; i++) 'n$i'};
      final edges = <String, Set<String>>{};
      for (var i = 0; i < n - 1; i++) {
        edges['n$i'] = {'n${i + 1}'};
      }
      edges['n${n - 1}'] = <String>{};

      final g = DependencyGraph(nodes: nodes, edges: edges);
      final order = topo(g);
      expectTopoValid(g, order);
    });
  });

  group('DependencyGraph - cycle detection', () {
    void expectCycleValid(
      DependencyGraph g,
      List<String>? cycle,
    ) {
      expect(cycle, isNotNull);
      final c = cycle!;
      // cycle is at least a -> a (length 2)
      expect(c.length, greaterThanOrEqualTo(2));
      expect(c.first, c.last);
      // each consecutive pair must be an edge
      for (var i = 0; i < c.length - 1; i++) {
        final u = c[i];
        final v = c[i + 1];
        expect(g.edges[u], contains(v));
      }
    }

    test('self-loop is detected and reported', () {
      final g = DependencyGraph(
        nodes: {'a'},
        edges: {
          'a': {'a'},
        },
      );

      try {
        g.topologicalOrder();
        fail('Expected GraphCycleError');
      } on GraphCycleError catch (e) {
        expect(e.message, contains('cycle'));
        expectCycleValid(g, e.cycle);
        // For a self-loop, a simple canonical cycle is [a, a]
        expect(e.cycle, equals(['a', 'a']));
      }
    });

    test('two-node cycle a <-> b', () {
      final g = DependencyGraph(
        nodes: {'a', 'b'},
        edges: {
          'a': {'b'},
          'b': {'a'},
        },
      );

      try {
        g.topologicalOrder();
        fail('Expected GraphCycleError');
      } on GraphCycleError catch (e) {
        expect(e.message, contains('cycle'));
        expectCycleValid(g, e.cycle);
        expect(e.cycle!.toSet(), containsAll(<String>{'a', 'b'}));
      }
    });

    test('three-node cycle a -> b -> c -> a', () {
      final g = DependencyGraph(
        nodes: {'a', 'b', 'c'},
        edges: {
          'a': {'b'},
          'b': {'c'},
          'c': {'a'},
        },
      );

      try {
        g.topologicalOrder();
        fail('Expected GraphCycleError');
      } on GraphCycleError catch (e) {
        expect(e.message, contains('cycle'));
        expectCycleValid(g, e.cycle);
        expect(e.cycle!.toSet(), containsAll(<String>{'a', 'b', 'c'}));
      }
    });
  });

  group('DependencyGraph - equality and hashCode', () {
    test('graphs with same content are equal and have same hashCode', () {
      final g1 = DependencyGraph(
        nodes: {'a', 'b', 'c'},
        edges: {
          'a': {'b'},
          'b': {'c'},
          'c': <String>{},
        },
      );

      // Build with different literal order
      final g2 = DependencyGraph(
        nodes: {'c', 'b', 'a'},
        edges: {
          'b': {'c'},
          'c': <String>{},
          'a': {'b'},
        },
      );

      expect(g1, equals(g2));
      expect(g1.hashCode, equals(g2.hashCode));
    });

    test('graphs differing in nodes or edges are not equal', () {
      final base = DependencyGraph(nodes: {
        'a',
        'b'
      }, edges: {
        'a': {'b'}
      });
      final differentNodes = DependencyGraph(nodes: {
        'a',
        'b',
        'c'
      }, edges: {
        'a': {'b'}
      });
      final differentEdges =
          DependencyGraph(nodes: {'a', 'b'}, edges: {'a': <String>{}});

      expect(base == differentNodes, isFalse);
      expect(base == differentEdges, isFalse);
    });
  });
}
