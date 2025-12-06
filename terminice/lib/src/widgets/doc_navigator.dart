import 'dart:io';

import '../style/theme.dart';
import '../system/hints.dart';
import '../system/framed_layout.dart';
import '../system/key_events.dart';
import '../system/prompt_runner.dart';
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
    final style = theme.style;

    // Expanded state is tracked by absolute path
    final Map<String, bool> expanded = {root.path: true};

    int selectedIndex = 0;
    int scrollOffset = 0;
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
        if (pIndex >= 0) selectedIndex = pIndex;
      }
    }

    void expand(_Entry e) {
      if (e.isDir) {
        expanded[e.path] = true;
      }
    }

    String selectedPath(List<_Entry> list) {
      if (list.isEmpty) return root.path;
      final s = list[selectedIndex.clamp(0, list.length - 1)];
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

    void render(RenderOutput out) {
      final frame = FramedLayout(title, theme: theme);
      final titleLine = frame.top();
      out.writeln(style.boldPrompt
          ? '${theme.bold}$titleLine${theme.reset}'
          : titleLine);

      final currentList = visible();
      final currentSel = selectedPath(currentList);
      final relSel = relPath(currentSel);

      // Root line and selection line
      out.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} ${theme.accent}Root:${theme.reset} ${_shortPath(root.path)}');
      out.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} ${theme.accent}Selected:${theme.reset} ${relSel.isEmpty ? '.' : relSel}');

      if (style.showBorder) {
        out.writeln(frame.connector());
      }

      // Keep selection within viewport
      if (selectedIndex < scrollOffset) scrollOffset = selectedIndex;
      if (selectedIndex >= scrollOffset + maxVisible) {
        scrollOffset = selectedIndex - maxVisible + 1;
      }
      final start = scrollOffset.clamp(0, currentList.length);
      final end = (scrollOffset + maxVisible).clamp(0, currentList.length);
      final window = currentList.sublist(start, end);

      if (start > 0) {
        out.writeln(
            '${theme.gray}${style.borderVertical}${theme.reset} ${theme.dim}...${theme.reset}');
      }

      for (var i = 0; i < window.length; i++) {
        final e = window[i];
        final isHighlighted = (start + i) == selectedIndex;
        final prefix =
            isHighlighted ? '${theme.accent}${style.arrow}${theme.reset}' : ' ';
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
        final framePrefix =
            '${theme.gray}${style.borderVertical}${theme.reset} ';
        if (isHighlighted && style.useInverseHighlight) {
          out.writeln('$framePrefix${theme.inverse}$lineText${theme.reset}');
        } else {
          out.writeln('$framePrefix$lineText');
        }
      }

      if (end < currentList.length) {
        out.writeln(
            '${theme.gray}${style.borderVertical}${theme.reset} ${theme.dim}...${theme.reset}');
      }

      if (currentList.isEmpty) {
        out.writeln(
            '${theme.gray}${style.borderVertical}${theme.reset} ${theme.dim}(no markdown files)${theme.reset}');
      }

      if (style.showBorder) {
        out.writeln(frame.bottom());
      }

      // Bottom controls and (optional) quick preview of first heading for files
      final sPath = selectedPath(currentList);
      final heading = _firstHeadingIfAny(sPath);
      if (heading != null && heading.isNotEmpty) {
        out.writeln('${theme.dim}Preview:${theme.reset} $heading');
      }

      out.writeln(Hints.grid([
        [Hints.key('↑/↓', theme), 'Navigate'],
        [Hints.key('→ / Enter', theme), 'Expand dir / Open file'],
        [Hints.key('←', theme), 'Collapse / Parent'],
        [Hints.key('Space', theme), 'Toggle'],
        [Hints.key('Ctrl+D', theme), 'Select file'],
        [Hints.key('Esc', theme), 'Exit'],
      ], theme));
    }

    final runner = PromptRunner(hideCursor: true);
    runner.run(
      render: render,
      onKey: (ev) {
        if (ev.type == KeyEventType.esc) return PromptResult.confirmed;
        if (ev.type == KeyEventType.ctrlC) {
          cancelled = true;
          return PromptResult.cancelled;
        }

        final list = visible();
        if (list.isEmpty) {
          return null;
        }
        final current = list[selectedIndex.clamp(0, list.length - 1)];

        if (ev.type == KeyEventType.arrowUp) {
          selectedIndex = (selectedIndex - 1 + list.length) % list.length;
        } else if (ev.type == KeyEventType.arrowDown) {
          selectedIndex = (selectedIndex + 1) % list.length;
        } else if (ev.type == KeyEventType.arrowRight) {
          expand(current);
        } else if (ev.type == KeyEventType.arrowLeft) {
          collapse(current);
        } else if (ev.type == KeyEventType.space) {
          toggle(current);
        } else if (ev.type == KeyEventType.enter) {
          if (current.isDir) {
            toggle(current);
          } else {
            // Open viewer for markdown file, then return to tree
            _viewMarkdown(current.path);
          }
        } else if (ev.type == KeyEventType.ctrlD) {
          // Quick select current file and exit
          if (!current.isDir) {
            result = current.path;
            return PromptResult.confirmed;
          }
        }

        // Maintain viewport
        if (selectedIndex < scrollOffset) {
          scrollOffset = selectedIndex;
        } else if (selectedIndex >= scrollOffset + maxVisible) {
          scrollOffset = selectedIndex - maxVisible + 1;
        }

        return null;
      },
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

    viewerOut.writeln(Hints.grid([
      [Hints.key('← / Esc / Enter', theme), 'Back to tree'],
    ], theme));

    while (true) {
      final ev = KeyEventReader.read();
      if (ev.type == KeyEventType.esc ||
          ev.type == KeyEventType.arrowLeft ||
          ev.type == KeyEventType.enter ||
          ev.type == KeyEventType.ctrlC) {
        break;
      }
    }

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
