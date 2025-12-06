import 'dart:io';

import '../style/theme.dart';
import '../system/hints.dart';
import '../system/key_bindings.dart';
import '../system/list_navigation.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';
import 'markdown_viewer.dart';

/// DocNavigator – navigate a Markdown docs tree.
///
/// Aligns with ThemeDemo styling:
/// - Themed title bar and bottom border
/// - Left gutter uses the theme's vertical border glyph
/// - Uses accent/highlight for selection and glyphs
class DocNavigator {
  final String title;
  final PromptTheme theme;
  final Directory root;
  final bool showHidden;
  final int maxVisible;

  DocNavigator({
    this.title = 'Doc Navigator',
    this.theme = PromptTheme.dark,
    Directory? root,
    this.showHidden = false,
    this.maxVisible = 18,
  }) : root = root ?? Directory.current;

  /// Returns the selected Markdown file path, or null if cancelled.
  String? run() {
    // Expanded state is tracked by absolute path
    final Map<String, bool> expanded = {root.path: true};

    // Use centralized list navigation for selection & scrolling
    final nav = ListNavigation(
      itemCount: 0, // Will be set after first visible() call
      maxVisible: maxVisible,
    );

    bool cancelled = false;
    String? result;

    // Build the visible list based on expansion map
    List<_Entry> visible() {
      final out = <_Entry>[];
      void walk(Directory dir, int depth, _Entry? parent, bool isLast,
          List<bool> lifelines) {
        final base = _Entry(
          name: _basename(dir.path),
          path: dir.path,
          isDir: true,
          depth: depth,
          parent: parent,
          isLast: isLast,
          lifelines: lifelines,
        );
        out.add(base);

        final isOpen = expanded[dir.path] ?? false;
        if (!isOpen) return;

        final children = _listChildren(dir);
        for (var i = 0; i < children.length; i++) {
          final child = children[i];
          final last = i == children.length - 1;
          if (child is Directory) {
            walk(
              child,
              depth + 1,
              base,
              last,
              [...lifelines, !base.isLast],
            );
          } else if (child is File) {
            out.add(
              _Entry(
                name: _basename(child.path),
                path: child.path,
                isDir: false,
                depth: depth + 1,
                parent: base,
                isLast: last,
                lifelines: [...lifelines, !base.isLast],
              ),
            );
          }
        }
      }

      walk(root, 0, null, true, const []);
      return out;
    }

    void toggle(_Entry e) {
      if (!e.isDir) return;
      expanded[e.path] = !(expanded[e.path] ?? false);
    }

    void collapse(_Entry e) {
      if (e.isDir && (expanded[e.path] ?? false)) {
        expanded[e.path] = false;
      } else if (e.parent != null) {
        final v = visible();
        final pIndex = v.indexWhere((x) => x == e.parent);
        if (pIndex >= 0) nav.jumpTo(pIndex);
      }
    }

    void expand(_Entry e) {
      if (e.isDir) {
        expanded[e.path] = true;
      }
    }

    String selectedPath(List<_Entry> list) {
      if (list.isEmpty) return root.path;
      final s = list[nav.selectedIndex];
      return s.path;
    }

    String relPath(String abs) {
      final rootP = root.path;
      if (abs.startsWith(rootP)) {
        final sub = abs.substring(rootP.length);
        return sub.startsWith(Platform.pathSeparator) ? sub.substring(1) : sub;
      }
      return abs;
    }

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings.verticalNavigation(
          onUp: () => nav.moveUp(),
          onDown: () => nav.moveDown(),
        ) +
        KeyBindings([
          // Right - expand
          KeyBinding.single(
            KeyEventType.arrowRight,
            (event) {
              final list = visible();
              if (list.isEmpty) return KeyActionResult.ignored;
              nav.itemCount = list.length;
              expand(list[nav.selectedIndex]);
              return KeyActionResult.handled;
            },
            hintLabel: '→ / Enter',
            hintDescription: 'Expand dir / Open file',
          ),
          // Left - collapse
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
              toggle(list[nav.selectedIndex]);
              return KeyActionResult.handled;
            },
            hintLabel: 'Space',
            hintDescription: 'Toggle',
          ),
          // Enter - toggle dir or open file
          KeyBinding.single(
            KeyEventType.enter,
            (event) {
              final list = visible();
              if (list.isEmpty) return KeyActionResult.ignored;
              nav.itemCount = list.length;
              final current = list[nav.selectedIndex];
              if (current.isDir) {
                toggle(current);
              } else {
                _viewMarkdown(current.path);
              }
              return KeyActionResult.handled;
            },
          ),
          // Ctrl+D - select file
          KeyBinding.single(
            KeyEventType.ctrlD,
            (event) {
              final list = visible();
              if (list.isEmpty) return KeyActionResult.ignored;
              nav.itemCount = list.length;
              final current = list[nav.selectedIndex];
              if (!current.isDir) {
                result = current.path;
                return KeyActionResult.confirmed;
              }
              return KeyActionResult.handled;
            },
            hintLabel: 'Ctrl+D',
            hintDescription: 'Select file',
          ),
          // Esc - exit
          KeyBinding.single(
            KeyEventType.esc,
            (event) => KeyActionResult.confirmed,
            hintLabel: 'Esc',
            hintDescription: 'Exit',
          ),
        ]) +
        KeyBindings.cancel(onCancel: () => cancelled = true);

    void render(RenderOutput out) {
      final widgetFrame = WidgetFrame(
        title: title,
        theme: theme,
        bindings: bindings,
        hintStyle: HintStyle.grid,
        showConnector: true,
      );

      widgetFrame.render(out, (ctx) {
        final currentList = visible();
        final currentSel = selectedPath(currentList);
        final relSel = relPath(currentSel);

        // Root line and selection line
        ctx.labeledValue('Root', _shortPath(root.path), dimLabel: false);
        ctx.labeledValue('Selected', relSel.isEmpty ? '.' : relSel, dimLabel: false);

        ctx.writeConnector();

        // Update nav's item count as tree structure changes
        nav.itemCount = currentList.length;

        // Use ListNavigation's viewport
        final window = nav.visibleWindow(currentList);

        if (window.hasOverflowAbove) {
          ctx.overflowIndicator();
        }

        for (var i = 0; i < window.items.length; i++) {
          final e = window.items[i];
          final absoluteIdx = window.start + i;
          final isHighlighted = nav.isSelected(absoluteIdx);
          final prefix = ctx.lb.arrow(isHighlighted);
          final branch = _treeBranchGlyph(e, theme);
          final toggleGlyph = e.isDir
              ? ((expanded[e.path] ?? false)
                  ? '${theme.accent}>${theme.reset}'
                  : '${theme.accent}+${theme.reset}')
              : ' ';
          final indent = _indentString(e);
          final labelColor = e.isDir
              ? theme.highlight
              : (e.name.toLowerCase().endsWith('.md')
                  ? theme.selection
                  : theme.gray);
          final lineText =
              '$prefix $indent$branch $toggleGlyph $labelColor${e.name}${theme.reset}';
          ctx.highlightedLine(lineText, highlighted: isHighlighted);
        }

        if (window.hasOverflowBelow) {
          ctx.overflowIndicator();
        }

        if (currentList.isEmpty) {
          ctx.emptyMessage('no markdown files');
        }

        // Bottom controls and (optional) quick preview of first heading for files
        final sPath = selectedPath(currentList);
        final heading = _firstHeadingIfAny(sPath);
        if (heading != null && heading.isNotEmpty) {
          ctx.line('${theme.dim}Preview:${theme.reset} $heading');
        }
      });
    }

    final runner = PromptRunner(hideCursor: true);
    runner.runWithBindings(
      render: render,
      bindings: bindings,
    );

    if (cancelled) return null;
    return result;
  }

  // --- helpers ---
  void _viewMarkdown(String path) {
    final label = 'Doc · ${_basename(path)}';
    final content = _readFileSafe(path);

    // Use RenderOutput for partial clearing (only clears our output)
    final viewerOut = RenderOutput();

    MarkdownViewer(
      content,
      theme: theme,
      title: label,
    ).showTo(viewerOut);

    // Use KeyBindings.back() for "back to tree" scenario
    final backBindings = KeyBindings.back(hintDescription: 'Back to tree');
    viewerOut.writeln(Hints.grid(backBindings.toHintEntries(), theme));

    // Wait for back key
    backBindings.waitForKey();

    // Clear just the viewer content when returning to tree
    viewerOut.clear();
  }

  List<FileSystemEntity> _listChildren(Directory dir) {
    final entries = dir
        .listSync(followLinks: false)
        .where((e) => showHidden || !_basename(e.path).startsWith('.'))
        .where((e) {
      if (e is Directory) return true;
      if (e is File) return e.path.toLowerCase().endsWith('.md');
      return false;
    }).toList();

    entries.sort((a, b) {
      final aDir = a is Directory;
      final bDir = b is Directory;
      if (aDir != bDir) return aDir ? -1 : 1;
      return _basename(a.path)
          .toLowerCase()
          .compareTo(_basename(b.path).toLowerCase());
    });
    return entries;
  }

  String? _firstHeadingIfAny(String path) {
    try {
      final f = File(path);
      if (!f.existsSync()) return null;
      if (!path.toLowerCase().endsWith('.md')) return null;
      for (final line in f.readAsLinesSync()) {
        final t = line.trimLeft();
        if (t.startsWith('# ')) {
          return '${theme.selection}${t.substring(2).trim()}${theme.reset}';
        }
        if (t.startsWith('## ')) {
          return '${theme.highlight}${t.substring(3).trim()}${theme.reset}';
        }
      }
    } catch (_) {}
    return null;
  }
}

class _Entry {
  final String name;
  final String path;
  final bool isDir;
  final int depth;
  final _Entry? parent;
  final bool isLast;
  final List<bool> lifelines; // draw verticals for ancestors

  const _Entry({
    required this.name,
    required this.path,
    required this.isDir,
    required this.depth,
    required this.parent,
    required this.isLast,
    required this.lifelines,
  });
}

String _basename(String path) {
  final parts = path.split(Platform.pathSeparator);
  return parts.isEmpty ? path : parts.last;
}

String _indentString(_Entry e) {
  if (e.depth <= 0) return '';
  final buffer = StringBuffer();
  for (var i = 0; i < e.depth - 1; i++) {
    buffer.write(e.lifelines[i] ? '│ ' : '  ');
  }
  return buffer.toString();
}

String _treeBranchGlyph(_Entry e, PromptTheme theme) {
  if (e.depth == 0) return ' ';
  final branch = e.isLast ? '└' : '├';
  return '${theme.gray}$branch${theme.reset}';
}

String _shortPath(String path, {int max = 60}) {
  return path.length > max
      ? '...${path.substring(path.length - (max - 3))}'
      : path;
}

String _readFileSafe(String path) {
  try {
    final f = File(path);
    if (!f.existsSync()) return '';
    return f.readAsStringSync();
  } catch (_) {
    return '';
  }
}
