import 'dart:io';

import '../style/theme.dart';
import '../system/key_bindings.dart';
import '../system/list_navigation.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

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
        return _basename(a.path)
            .toLowerCase()
            .compareTo(_basename(b.path).toLowerCase());
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
      list.add(
          _Entry('✓ Select this directory', dir.path, _EntryType.confirmDir));

      for (final e in filtered) {
        if (e is Directory) {
          list.add(
              _Entry('▸ ${_basename(e.path)}', e.path, _EntryType.directory));
        } else if (allowFiles && e is File) {
          list.add(_Entry('· ${_basename(e.path)}', e.path, _EntryType.file));
        }
      }
      return list;
    }

    String shortPath(String path) {
      return path.length > 60 ? '...${path.substring(path.length - 57)}' : path;
    }

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings.verticalNavigation(
          onUp: () => nav.moveUp(),
          onDown: () => nav.moveDown(),
        ) +
        KeyBindings([
          // Left - parent directory
          KeyBinding.single(
            KeyEventType.arrowLeft,
            (event) {
              if (current.parent.path != current.path) {
                current = current.parent;
                nav.reset();
              }
              return KeyActionResult.handled;
            },
            hintLabel: '←',
            hintDescription: 'Parent directory',
          ),
          // Right / Enter - enter directory or select
          KeyBinding.multi(
            {KeyEventType.arrowRight, KeyEventType.enter},
            (event) {
              final entries = readEntries(current);
              if (entries.isEmpty) return KeyActionResult.ignored;
              nav.itemCount = entries.length;
              final cur = entries[nav.selectedIndex];
              if (cur.type == _EntryType.up) {
                current = Directory(cur.path);
                nav.reset();
              } else if (cur.type == _EntryType.confirmDir) {
                selectedPath = current.path;
                return KeyActionResult.confirmed;
              } else if (cur.type == _EntryType.directory) {
                current = Directory(cur.path);
                nav.reset();
              } else if (cur.type == _EntryType.file && allowFiles) {
                selectedPath = cur.path;
                return KeyActionResult.confirmed;
              }
              return KeyActionResult.handled;
            },
            hintLabel: '→ / Enter',
            hintDescription: 'Enter directory / Select',
          ),
        ]) +
        KeyBindings.cancel();

    // Use WidgetFrame for consistent frame rendering
    final frame = WidgetFrame(
      title: label,
      theme: theme,
      bindings: bindings,
      showConnector: true,
      hintStyle: HintStyle.grid,
    );

    void render(RenderOutput out) {
      frame.render(out, (ctx) {
        // Current path line
        ctx.headerLine('Path', shortPath(current.path));

        // Connector after path
        ctx.writeConnector();

        final entries = readEntries(current);
        nav.itemCount = entries.length;

        if (entries.isEmpty) {
          ctx.emptyMessage('empty');
        }

        // Use ListNavigation's viewport
        final window = nav.visibleWindow(entries);

        ctx.listWindow(
          window,
          selectedIndex: nav.selectedIndex,
          renderItem: (entry, index, isFocused) {
            final prefix = ctx.lb.arrow(isFocused);
            final lineText = '$prefix ${entry.label}';
            ctx.highlightedLine(lineText, highlighted: isFocused);
          },
        );
      });
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: render,
      bindings: bindings,
    );

    return (result == PromptResult.confirmed && selectedPath != null)
        ? selectedPath!
        : '';
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
