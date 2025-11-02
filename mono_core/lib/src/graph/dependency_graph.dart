import 'dart:collection';

import 'package:collection/collection.dart';

import 'package:mono_core/mono_core.dart';

@immutable
class DependencyGraph {
  DependencyGraph({required Set<String> nodes, Map<String, Set<String>>? edges})
      : nodes = Set.unmodifiable(nodes),
        edges = Map.unmodifiable(
          (edges ?? const <String, Set<String>>{}).map(
            (k, v) => MapEntry(k, Set.unmodifiable(v)),
          ),
        );

  final Set<String> nodes;
  final Map<String, Set<String>> edges;

  Set<String> dependenciesOf(String node) => edges[node] ?? const {};

  List<String> topologicalOrder() {
    final inDegree = <String, int>{for (final n in nodes) n: 0};
    for (final deps in edges.values) {
      for (final d in deps) {
        if (inDegree.containsKey(d)) inDegree[d] = inDegree[d]! + 1;
      }
    }
    final queue = ListQueue<String>.from(
      inDegree.entries.where((e) => e.value == 0).map((e) => e.key),
    );
    final result = <String>[];
    final mutableEdges = edges.map((k, v) => MapEntry(k, v.toSet()));
    while (queue.isNotEmpty) {
      final n = queue.removeFirst();
      result.add(n);
      for (final m in mutableEdges[n] ?? const <String>{}) {
        inDegree[m] = inDegree[m]! - 1;
        if (inDegree[m] == 0) queue.add(m);
      }
      mutableEdges[n] = <String>{};
    }
    if (result.length != nodes.length) {
      throw GraphCycleError('Dependency graph contains a cycle',
          cycle: _findAnyCycle());
    }
    return result;
  }

  List<String>? _findAnyCycle() {
    final visited = <String>{};
    final stack = <String>{};
    final parent = <String, String?>{};
    List<String>? dfs(String node) {
      visited.add(node);
      stack.add(node);
      for (final dep in edges[node] ?? const <String>{}) {
        if (!visited.contains(dep)) {
          parent[dep] = node;
          final r = dfs(dep);
          if (r != null) return r;
        } else if (stack.contains(dep)) {
          final cycle = <String>[dep];
          var cur = node;
          while (cur != dep) {
            cycle.add(cur);
            cur = parent[cur]!;
          }
          cycle.add(dep);
          return cycle.reversed.toList();
        }
      }
      stack.remove(node);
      return null;
    }

    for (final n in nodes) {
      if (!visited.contains(n)) {
        parent[n] = null;
        final found = dfs(n);
        if (found != null) return found;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DependencyGraph &&
          const SetEquality().equals(nodes, other.nodes) &&
          _mapSetEq(edges, other.edges);
  @override
  int get hashCode => Object.hash(
        const SetEquality().hash(nodes),
        _mapSetHash(edges),
      );
}

bool _mapSetEq(Map<String, Set<String>> a, Map<String, Set<String>> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  final setEq = const SetEquality<String>();
  for (final entry in a.entries) {
    final other = b[entry.key];
    if (other == null) return false;
    if (!setEq.equals(entry.value, other)) return false;
  }
  return true;
}

int _mapSetHash(Map<String, Set<String>> m) {
  final setEq = const SetEquality<String>();
  return m.entries
      .map((e) => Object.hash(e.key, setEq.hash(e.value)))
      .fold(0, (a, b) => a ^ b);
}
