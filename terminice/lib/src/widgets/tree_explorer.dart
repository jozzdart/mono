import '../style/theme.dart';
import '../system/key_events.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/prompt_runner.dart';

class TreeNode {
  final String label;
  final List<TreeNode> children;
  final bool initiallyExpanded;

  const TreeNode(this.label, {this.children = const [], this.initiallyExpanded = false});

  bool get isLeaf => children.isEmpty;
}

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

  /// Returns the selected node's label path (e.g., "root/child/grandchild"), or null if cancelled.
  String? run() {
    final style = theme.style;

    final expanded = <TreeNode, bool>{};
    for (final r in roots) {
      expanded[r] = r.initiallyExpanded;
      _initExpanded(r, expanded);
    }

    int selectedIndex = 0;
    int scrollOffset = 0;
    bool cancelled = false;
    bool confirmed = false;

    List<_VisibleEntry> visible() {
      final list = <_VisibleEntry>[];
      for (var i = 0; i < roots.length; i++) {
        final r = roots[i];
        _buildVisible(
          r,
          0,
          list,
          expanded,
          null,
          i == roots.length - 1,
          const [],
        );
      }
      return list;
    }

    String entryToPath(_VisibleEntry e) {
      final parts = <String>[];
      void ascend(_VisibleEntry cur) {
        parts.insert(0, cur.node.label);
        if (cur.parent != null) ascend(cur.parent!);
      }
      ascend(e);
      return parts.join('/');
    }

    void toggle(_VisibleEntry e) {
      if (e.node.isLeaf) return;
      expanded[e.node] = !(expanded[e.node] ?? false);
    }

    void collapse(_VisibleEntry e) {
      if (!e.node.isLeaf && (expanded[e.node] ?? false)) {
        expanded[e.node] = false;
      } else if (e.parent != null) {
        // If already collapsed, move focus to parent
        final v = visible();
        final parentIndex = v.indexWhere((x) => x == e.parent);
        if (parentIndex >= 0) selectedIndex = parentIndex;
      }
    }

    void expand(_VisibleEntry e) {
      if (!e.node.isLeaf) {
        expanded[e.node] = true;
      }
    }

    void render(RenderOutput out) {
      final frame = FramedLayout(title, theme: theme);
      final top = frame.top();
      out.writeln(style.boldPrompt ? '${theme.bold}$top${theme.reset}' : top);

      if (style.showBorder) {
        out.writeln(frame.connector());
      }

      final list = visible();
      // Keep selection within viewport
      if (selectedIndex < scrollOffset) scrollOffset = selectedIndex;
      if (selectedIndex >= scrollOffset + maxVisible) {
        scrollOffset = selectedIndex - maxVisible + 1;
      }
      final start = scrollOffset.clamp(0, list.length);
      final end = (scrollOffset + maxVisible).clamp(0, list.length);
      final window = list.sublist(start, end);

      if (start > 0) {
        out.writeln(
            '${theme.gray}${style.borderVertical}${theme.reset} ${theme.dim}...${theme.reset}');
      }

      for (var i = 0; i < window.length; i++) {
        final e = window[i];
        final isHighlighted = (start + i) == selectedIndex;
        final prefix = isHighlighted ? '${theme.accent}${style.arrow}${theme.reset}' : ' ';
        final branch = _treeBranchGlyph(e, theme);
        final toggleGlyph = e.node.isLeaf
            ? ' '
            : ((expanded[e.node] ?? false)
                ? '${theme.accent}>${theme.reset}'
                : '${theme.accent}+${theme.reset}');
        final indent = _indentString(e);
        final lineText = '$prefix $indent$branch $toggleGlyph ${e.node.label}';
        final framePrefix = '${theme.gray}${style.borderVertical}${theme.reset} ';
        if (isHighlighted && style.useInverseHighlight) {
          out.writeln('$framePrefix${theme.inverse}$lineText${theme.reset}');
        } else {
          out.writeln('$framePrefix$lineText');
        }
      }

      if (end < list.length) {
        out.writeln(
            '${theme.gray}${style.borderVertical}${theme.reset} ${theme.dim}...${theme.reset}');
      }

      if (list.isEmpty) {
        out.writeln(
            '${theme.gray}${style.borderVertical}${theme.reset} ${theme.dim}(empty)${theme.reset}');
      }

      if (style.showBorder) {
        out.writeln(frame.bottom());
      }

      out.writeln(Hints.grid([
        [Hints.key('↑/↓', theme), 'Navigate'],
        [Hints.key('→ / Enter', theme), 'Expand / Select'],
        [Hints.key('←', theme), 'Collapse / Parent'],
        [Hints.key('Space', theme), 'Toggle'],
        [Hints.key('Esc', theme), 'Exit'],
      ], theme));
    }

    final runner = PromptRunner(hideCursor: true);
    runner.run(
      render: render,
      onKey: (ev) {
        if (ev.type == KeyEventType.esc) {
          return PromptResult.confirmed; // exit without selection
        }
        if (ev.type == KeyEventType.ctrlC) {
          cancelled = true;
          return PromptResult.cancelled;
        }

        final list = visible();
        if (list.isEmpty) return null;
        final current = list[selectedIndex.clamp(0, list.length - 1)];

        if (ev.type == KeyEventType.arrowUp) {
          selectedIndex = (selectedIndex - 1 + list.length) % list.length;
        } else if (ev.type == KeyEventType.arrowDown) {
          selectedIndex = (selectedIndex + 1) % list.length;
        } else if (ev.type == KeyEventType.arrowRight || ev.type == KeyEventType.enter || ev.type == KeyEventType.space) {
          if (current.node.isLeaf) {
            confirmed = true;
            return PromptResult.confirmed; // select leaf
          } else {
            if (ev.type == KeyEventType.arrowRight) {
              expand(current);
            } else {
              toggle(current);
            }
          }
        } else if (ev.type == KeyEventType.arrowLeft) {
          collapse(current);
        }

        return null;
      },
    );

    if (cancelled) return null;
    final v = visible();
    if (v.isEmpty) return null;
    final selected = v[selectedIndex.clamp(0, v.length - 1)];
    return confirmed ? entryToPath(selected) : null;
  }

  void _initExpanded(TreeNode node, Map<TreeNode, bool> expanded) {
    if (node.children.isEmpty) return;
    for (final c in node.children) {
      expanded.putIfAbsent(c, () => c.initiallyExpanded);
      _initExpanded(c, expanded);
    }
  }
}

class _VisibleEntry {
  final TreeNode node;
  final int depth;
  final _VisibleEntry? parent;
  final bool isLast;
  final List<bool> lifelines; // draw verticals for ancestors
  const _VisibleEntry(this.node, this.depth, this.parent, this.isLast, this.lifelines);
}

void _buildVisible(
  TreeNode node,
  int depth,
  List<_VisibleEntry> out,
  Map<TreeNode, bool> expanded, [
  _VisibleEntry? parent,
  bool isLast = true,
  List<bool> lifelines = const [],
]) {
  final entry = _VisibleEntry(node, depth, parent, isLast, lifelines);
  out.add(entry);
  if (!(expanded[node] ?? false)) return;
  for (var i = 0; i < node.children.length; i++) {
    final c = node.children[i];
    final last = i == node.children.length - 1;
    _buildVisible(
      c,
      depth + 1,
      out,
      expanded,
      entry,
      last,
      [...lifelines, !entry.isLast],
    );
  }
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
