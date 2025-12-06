import 'dart:io';

import '../style/theme.dart';
import '../system/key_events.dart';
import '../system/hints.dart';
import '../system/framed_layout.dart';
import '../system/list_navigation.dart';
import '../system/prompt_runner.dart';

/// PathNavigator – interactive directory (and optional file) navigation.
///
/// - Arrow ↑/↓ to move selection
/// - Enter / → to enter a directory
/// - ← to go to parent directory
/// - Enter on "✓ Select this directory" to confirm current directory
/// - Esc cancels
class PathNavigator {
  final String label;
  final PromptTheme theme;
  final Directory startDir;
  final bool showHidden;
  final bool allowFiles; // If true, selecting a file returns its path
  final int maxVisible;

  PathNavigator({
    this.label = 'Path Navigator',
    this.theme = PromptTheme.dark,
    Directory? startDir,
    this.showHidden = false,
    this.allowFiles = false,
    this.maxVisible = 18,
  }) : startDir = startDir ?? Directory.current;

  /// Returns a selected path, or empty string if cancelled.
  String run() {
    final style = theme.style;

    Directory current = startDir;
    String? selectedPath;

    // Use centralized list navigation for selection & scrolling
    final nav = ListNavigation(
      itemCount: 0, // Will be set after first readEntries() call
      maxVisible: maxVisible,
    );

    List<_Entry> readEntries(Directory dir) {
      final raw = dir.listSync(followLinks: false);
      raw.sort((a, b) {
        final aDir = a is Directory;
        final bDir = b is Directory;
        if (aDir != bDir) return aDir ? -1 : 1;
        return _basename(a.path).toLowerCase().compareTo(_basename(b.path).toLowerCase());
      });

      final filtered = raw
          .where((e) => showHidden || !_basename(e.path).startsWith('.'))
          .toList();

      final List<_Entry> list = [];

      // Optional parent navigation.
      final hasParent = dir.parent.path != dir.path;
      if (hasParent) {
        list.add(_Entry('↩ ..', dir.parent.path, _EntryType.up));
      }

      // Select current directory entry
      list.add(_Entry('✓ Select this directory', dir.path, _EntryType.confirmDir));

      for (final e in filtered) {
        if (e is Directory) {
          list.add(_Entry('▸ ${_basename(e.path)}', e.path, _EntryType.directory));
        } else if (allowFiles && e is File) {
          list.add(_Entry('· ${_basename(e.path)}', e.path, _EntryType.file));
        }
      }
      return list;
    }

    String shortPath(String path) {
      return path.length > 60 ? '...${path.substring(path.length - 57)}' : path;
    }

    void render(RenderOutput out) {
      final frame = FramedLayout(label, theme: theme);
      final title = frame.top();
      out.writeln(style.boldPrompt ? '${theme.bold}$title${theme.reset}' : title);

      // Current path line
      final pathLine = '${theme.gray}${style.borderVertical}${theme.reset} ${theme.accent}Path:${theme.reset} ${shortPath(current.path)}';
      out.writeln(pathLine);

      if (style.showBorder) {
        out.writeln(frame.connector());
      }

      final entries = readEntries(current);
      nav.itemCount = entries.length;

      if (entries.isEmpty) {
        out.writeln(
            '${theme.gray}${style.borderVertical}${theme.reset} ${theme.dim}(empty)${theme.reset}');
      }

      // Use ListNavigation's viewport
      final window = nav.visibleWindow(entries);

      if (window.hasOverflowAbove) {
        out.writeln('${theme.gray}${style.borderVertical}${theme.reset} ${theme.dim}...${theme.reset}');
      }

      for (var i = 0; i < window.items.length; i++) {
        final absoluteIdx = window.start + i;
        final e = window.items[i];
        final isHighlighted = nav.isSelected(absoluteIdx);
        final prefix = isHighlighted ? '${theme.accent}${style.arrow}${theme.reset}' : ' ';
        final lineText = '$prefix ${e.label}';
        final framePrefix = '${theme.gray}${style.borderVertical}${theme.reset} ';
        if (isHighlighted && style.useInverseHighlight) {
          out.writeln('$framePrefix${theme.inverse}$lineText${theme.reset}');
        } else {
          out.writeln('$framePrefix$lineText');
        }
      }

      if (window.hasOverflowBelow) {
        out.writeln('${theme.gray}${style.borderVertical}${theme.reset} ${theme.dim}...${theme.reset}');
      }

      if (style.showBorder) {
        out.writeln(frame.bottom());
      }

      out.writeln(Hints.grid([
        [Hints.key('↑/↓', theme), 'Navigate'],
        [Hints.key('→ / Enter', theme), 'Enter directory / Select'],
        [Hints.key('←', theme), 'Parent directory'],
        [Hints.key('Esc', theme), 'Cancel'],
      ], theme));
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.run(
      render: render,
      onKey: (ev) {
        if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
          return PromptResult.cancelled;
        }

        final entries = readEntries(current);
        if (entries.isEmpty) {
          return null;
        }
        nav.itemCount = entries.length; // Keep in sync

        if (ev.type == KeyEventType.arrowUp) {
          nav.moveUp();
        } else if (ev.type == KeyEventType.arrowDown) {
          nav.moveDown();
        } else if (ev.type == KeyEventType.arrowLeft) {
          // go to parent
          if (current.parent.path != current.path) {
            current = current.parent;
            nav.reset();
          }
        } else if (ev.type == KeyEventType.arrowRight || ev.type == KeyEventType.enter) {
          final cur = entries[nav.selectedIndex];
          if (cur.type == _EntryType.up) {
            current = Directory(cur.path);
            nav.reset();
          } else if (cur.type == _EntryType.confirmDir) {
            selectedPath = current.path;
            return PromptResult.confirmed;
          } else if (cur.type == _EntryType.directory) {
            current = Directory(cur.path);
            nav.reset();
          } else if (cur.type == _EntryType.file && allowFiles) {
            selectedPath = cur.path;
            return PromptResult.confirmed;
          }
        }

        return null;
      },
    );

    return (result == PromptResult.confirmed && selectedPath != null) ? selectedPath! : '';
  }
}

class _Entry {
  final String label;
  final String path;
  final _EntryType type;
  _Entry(this.label, this.path, this.type);
}

enum _EntryType { up, confirmDir, directory, file }

String _basename(String path) {
  final parts = path.split(Platform.pathSeparator);
  return parts.isEmpty ? path : parts.last;
}


