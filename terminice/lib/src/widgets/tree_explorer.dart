import '../style/theme.dart';
import '../system/key_bindings.dart';
import '../system/list_navigation.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

class TreeNode {
  final String label;
  final List<TreeNode> children;
  final bool initiallyExpanded;

  const TreeNode(this.label,
      {this.children = const [], this.initiallyExpanded = false});

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
    final expanded = <TreeNode, bool>{};
    for (final r in roots) {
      expanded[r] = r.initiallyExpanded;
      _initExpanded(r, expanded);
    }

    // Use centralized list navigation for selection & scrolling
    // Note: itemCount will be dynamically updated as tree expands/collapses
    final nav = ListNavigation(
      itemCount: 0, // Will be set after first visible() call
      maxVisible: maxVisible,
    );

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
        if (parentIndex >= 0) nav.jumpTo(parentIndex);
      }
    }

    void expand(_VisibleEntry e) {
      if (!e.node.isLeaf) {
        expanded[e.node] = true;
      }
    }

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings.verticalNavigation(
          onUp: () => nav.moveUp(),
          onDown: () => nav.moveDown(),
        ) +
        KeyBindings([
          // Right / Enter - expand or select
          KeyBinding.multi(
            {KeyEventType.arrowRight, KeyEventType.enter},
            (event) {
              final list = visible();
              if (list.isEmpty) return KeyActionResult.ignored;
              nav.itemCount = list.length;
              final current = list[nav.selectedIndex];

              if (current.node.isLeaf) {
                confirmed = true;
                return KeyActionResult.confirmed;
              } else {
                if (event.type == KeyEventType.arrowRight) {
                  expand(current);
                } else {
                  toggle(current);
                }
              }
              return KeyActionResult.handled;
            },
            hintLabel: '→ / Enter',
            hintDescription: 'Expand / Select',
          ),
          // Left - collapse or parent
          KeyBinding.single(
            KeyEventType.arrowLeft,
            (event) {
              final list = visible();
              if (list.isEmpty) return KeyActionResult.ignored;
              nav.itemCount = list.length;
              collapse(list[nav.selectedIndex]);
              return KeyActionResult.handled;
            },
            hintLabel: '←',
            hintDescription: 'Collapse / Parent',
          ),
          // Space - toggle
          KeyBinding.single(
            KeyEventType.space,
            (event) {
              final list = visible();
              if (list.isEmpty) return KeyActionResult.ignored;
              nav.itemCount = list.length;
              final current = list[nav.selectedIndex];
              if (current.node.isLeaf) {
                confirmed = true;
                return KeyActionResult.confirmed;
              }
              toggle(current);
              return KeyActionResult.handled;
            },
            hintLabel: 'Space',
            hintDescription: 'Toggle',
          ),
        ]) +
        KeyBindings([
          // Esc - exit without selection
          KeyBinding.single(
            KeyEventType.esc,
            (event) => KeyActionResult.confirmed,
            hintLabel: 'Esc',
            hintDescription: 'Exit',
          ),
        ]) +
        KeyBindings.cancel(onCancel: () => cancelled = true);

    // Use WidgetFrame for consistent frame rendering
    final frame = WidgetFrame(
      title: title,
      theme: theme,
      bindings: bindings,
      showConnector: true,
      hintStyle: HintStyle.grid,
    );

    void render(RenderOutput out) {
      frame.render(out, (ctx) {
        final list = visible();
        // Update nav's item count as tree structure changes
        nav.itemCount = list.length;

        // Use ListNavigation's viewport
        final window = nav.visibleWindow(list);

        ctx.listWindow(
          window,
          selectedIndex: nav.selectedIndex,
          renderItem: (entry, index, isFocused) {
            final prefix = ctx.lb.arrow(isFocused);
            final branch = _treeBranchGlyph(entry, theme);
            final toggleGlyph = entry.node.isLeaf
                ? ' '
                : ((expanded[entry.node] ?? false)
                    ? '${theme.accent}>${theme.reset}'
                    : '${theme.accent}+${theme.reset}');
            final indent = _indentString(entry);
            final lineText =
                '$prefix $indent$branch $toggleGlyph ${entry.node.label}';
            ctx.highlightedLine(lineText, highlighted: isFocused);
          },
        );

        if (list.isEmpty) {
          ctx.emptyMessage('empty');
        }
      });
    }

    final runner = PromptRunner(hideCursor: true);
    runner.runWithBindings(
      render: render,
      bindings: bindings,
    );

    if (cancelled) return null;
    final v = visible();
    if (v.isEmpty) return null;
    final selected = v[nav.selectedIndex];
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
  const _VisibleEntry(
      this.node, this.depth, this.parent, this.isLast, this.lifelines);
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
