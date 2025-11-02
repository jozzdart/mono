import 'package:mono_cli/mono_cli.dart';

@immutable
class DefaultTargetSelector implements TargetSelector {
  const DefaultTargetSelector();

  @override
  List<MonoPackage> resolve({
    required List<TargetExpr> expressions,
    required List<MonoPackage> packages,
    required Map<String, Set<String>> groups,
    required DependencyGraph graph,
    required bool dependencyOrder,
  }) {
    final nameToPkg = {for (final p in packages) p.name.value: p};
    final selectedNames = <String>[];

    List<String> expandGroup(String groupName, Set<String> seenGroups) {
      if (seenGroups.contains(groupName)) return const <String>[];
      seenGroups.add(groupName);
      final members = groups[groupName] ?? const <String>{};
      final out = <String>[];
      for (final m in members) {
        if (m.startsWith(':')) {
          out.addAll(expandGroup(m.substring(1), seenGroups));
        } else if (nameToPkg.containsKey(m)) {
          out.add(m);
        } else {
          // treat as glob pattern against package names
          final re = _globToRegExp(m);
          out.addAll(nameToPkg.keys.where((n) => re.hasMatch(n)));
        }
      }
      return out;
    }

    void addName(String name) {
      if (!selectedNames.contains(name)) selectedNames.add(name);
    }

    if (expressions.isEmpty) {
      for (final p in packages) {
        addName(p.name.value);
      }
    } else {
      for (final expr in expressions) {
        if (expr is TargetAll) {
          for (final p in packages) {
            addName(p.name.value);
          }
        } else if (expr is TargetPackage) {
          if (nameToPkg.containsKey(expr.name)) addName(expr.name);
        } else if (expr is TargetGroup) {
          for (final n in expandGroup(expr.groupName, <String>{})) {
            addName(n);
          }
        } else if (expr is TargetGlob) {
          final re = _globToRegExp(expr.pattern);
          for (final n in nameToPkg.keys.where((n) => re.hasMatch(n))) {
            addName(n);
          }
        }
      }
    }

    if (!dependencyOrder) {
      return selectedNames.map((n) => nameToPkg[n]!).toList(growable: false);
    }

    final order = graph.topologicalOrder();
    final inSelected = selectedNames.toSet();
    final ordered = [
      for (final n in order)
        if (inSelected.contains(n)) nameToPkg[n]!
    ];
    return ordered;
  }
}

RegExp _globToRegExp(String pattern) {
  final escaped =
      pattern.replaceAllMapped(RegExp(r'[.+^${}()|\\]'), (m) => '\\${m[0]}');
  final re = '^${escaped.replaceAll('*', '.*').replaceAll('?', '.')}\$';
  return RegExp(re);
}
