import '../style/theme.dart';
import '../system/dynamic_list_prompt.dart';

/// A node in the tree.
class TreeNode {
  final String label;
  final List<TreeNode> children;
  final bool initiallyExpanded;

  const TreeNode(this.label,
      {this.children = const [], this.initiallyExpanded = false});

  bool get isLeaf => children.isEmpty;
}

/// TreeExplorer – interactive tree navigation with expand/collapse.
///
/// Controls:
/// - ↑ / ↓ to navigate
/// - → / Enter to expand or select leaf
/// - ← to collapse or go to parent
/// - Space to toggle expand/collapse
/// - Esc to exit
///
/// **Implementation:** Uses [DynamicListPrompt] for core functionality,
/// demonstrating composition over inheritance.
class TreeExplorer {
  final String title;
  final List<TreeNode> roots;
  final PromptTheme theme;
  final bool allowCollapseAll;
  final int maxVisible;

  TreeExplorer({
    required this.title,
    required this.roots,
    this.theme = PromptTheme.dark,
    this.allowCollapseAll = true,
    this.maxVisible = 18,
  });

  /// Returns the selected node's label path (e.g., "root/child/grandchild"),
  /// or null if cancelled.
  String? run() {
    if (roots.isEmpty) return null;

    // Track expanded state
    final expanded = <TreeNode, bool>{};
    for (final r in roots) {
      expanded[r] = r.initiallyExpanded;
      _initExpanded(r, expanded);
    }

    // Track confirmed selection
    bool confirmed = false;

    final prompt = DynamicListPrompt<_VisibleEntry>(
      title: title,
      theme: theme,
      maxVisible: maxVisible,
    );

    final result = prompt.run(
      buildItems: () => _buildVisible(roots, expanded),

      onPrimary: (entry, index) {
        if (entry.node.isLeaf) {
          confirmed = true;
          return DynamicAction.confirm;
        }
        // Expand if not expanded
        expanded[entry.node] = true;
        return DynamicAction.rebuild;
      },

      onSecondary: (entry, index) {
        if (!entry.node.isLeaf && (expanded[entry.node] ?? false)) {
          // Collapse if expanded
          expanded[entry.node] = false;
          return DynamicAction.rebuild;
        }
        // Otherwise, try to focus parent
        if (entry.parent != null) {
          final items = _buildVisible(roots, expanded);
          final parentIdx = items.indexWhere((e) => e.node == entry.parent!.node);
          if (parentIdx >= 0) {
            prompt.nav.jumpTo(parentIdx);
          }
        }
        return DynamicAction.none;
      },

      onToggle: (entry, index) {
        if (entry.node.isLeaf) {
          confirmed = true;
          return DynamicAction.confirm;
        }
        expanded[entry.node] = !(expanded[entry.node] ?? false);
        return DynamicAction.rebuild;
      },

      renderItem: (ctx, entry, index, isFocused) {
        final arrow = ctx.lb.arrow(isFocused);
        final branch = _treeBranchGlyph(entry, theme);
        final toggleGlyph = entry.node.isLeaf
            ? ' '
            : ((expanded[entry.node] ?? false)
                ? '${theme.accent}>${theme.reset}'
                : '${theme.accent}+${theme.reset}');
        final indent = _indentString(entry);

        ctx.highlightedLine(
          '$arrow $indent$branch $toggleGlyph ${entry.node.label}',
          highlighted: isFocused,
        );
      },
    );

    if (result == null || !confirmed) return null;
    return _entryToPath(result);
  }

  void _initExpanded(TreeNode node, Map<TreeNode, bool> expanded) {
    for (final c in node.children) {
      expanded.putIfAbsent(c, () => c.initiallyExpanded);
      _initExpanded(c, expanded);
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// INTERNAL HELPERS
// ════════════════════════════════════════════════════════════════════════════

class _VisibleEntry {
  final TreeNode node;
  final int depth;
  final _VisibleEntry? parent;
  final bool isLast;
  final List<bool> lifelines;

  const _VisibleEntry(
      this.node, this.depth, this.parent, this.isLast, this.lifelines);
}

List<_VisibleEntry> _buildVisible(
  List<TreeNode> roots,
  Map<TreeNode, bool> expanded,
) {
  final result = <_VisibleEntry>[];

  void traverse(
    TreeNode node,
    int depth,
    _VisibleEntry? parent,
    bool isLast,
    List<bool> lifelines,
  ) {
    final entry = _VisibleEntry(node, depth, parent, isLast, lifelines);
    result.add(entry);

    if (expanded[node] ?? false) {
      for (var i = 0; i < node.children.length; i++) {
        final child = node.children[i];
        final childIsLast = i == node.children.length - 1;
        traverse(
          child,
          depth + 1,
          entry,
          childIsLast,
          [...lifelines, !isLast],
        );
      }
    }
  }

  for (var i = 0; i < roots.length; i++) {
    traverse(roots[i], 0, null, i == roots.length - 1, const []);
  }

  return result;
}

String _entryToPath(_VisibleEntry e) {
  final parts = <String>[];
  _VisibleEntry? current = e;
  while (current != null) {
    parts.insert(0, current.node.label);
    current = current.parent;
  }
  return parts.join('/');
}

String _indentString(_VisibleEntry e) {
  if (e.depth <= 0) return '';
  final buffer = StringBuffer();
  for (var i = 0; i < e.depth - 1; i++) {
    buffer.write(e.lifelines[i] ? '│ ' : '  ');
  }
  return buffer.toString();
}

String _treeBranchGlyph(_VisibleEntry e, PromptTheme theme) {
  if (e.depth == 0) return ' ';
  final branch = e.isLast ? '└' : '├';
  return '${theme.gray}$branch${theme.reset}';
}
