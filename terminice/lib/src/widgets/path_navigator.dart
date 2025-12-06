import 'dart:io';

import '../style/theme.dart';
import '../system/dynamic_list_prompt.dart';

/// PathNavigator – interactive directory (and optional file) navigation.
///
/// Controls:
/// - Arrow ↑/↓ to move selection
/// - Enter / → to enter a directory
/// - ← to go to parent directory
/// - Enter on "✓ Select this directory" to confirm current directory
/// - Esc cancels
///
/// **Implementation:** Uses [DynamicListPrompt] for core functionality,
/// demonstrating composition over inheritance.
class PathNavigator {
  final String label;
  final PromptTheme theme;
  final Directory startDir;
  final bool showHidden;
  final bool allowFiles;
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

    final prompt = DynamicListPrompt<_Entry>(
      title: label,
      theme: theme,
      maxVisible: maxVisible,
    );

    final result = prompt.run(
      buildItems: () => _readEntries(current, showHidden, allowFiles),

      onPrimary: (entry, index) {
        switch (entry.type) {
          case _EntryType.up:
            current = Directory(entry.path);
            return DynamicAction.rebuildAndReset;
          case _EntryType.confirmDir:
            selectedPath = current.path;
            return DynamicAction.confirm;
          case _EntryType.directory:
            current = Directory(entry.path);
            return DynamicAction.rebuildAndReset;
          case _EntryType.file:
            if (allowFiles) {
              selectedPath = entry.path;
              return DynamicAction.confirm;
            }
            return DynamicAction.none;
        }
      },

      onSecondary: (entry, index) {
        // Go to parent
        if (current.parent.path != current.path) {
          current = current.parent;
          return DynamicAction.rebuildAndReset;
        }
        return DynamicAction.none;
      },

      beforeItems: (ctx) {
        final shortPath = current.path.length > 60
            ? '...${current.path.substring(current.path.length - 57)}'
            : current.path;
        ctx.headerLine('Path', shortPath);
        ctx.writeConnector();
      },

      renderItem: (ctx, entry, index, isFocused) {
        final arrow = ctx.lb.arrow(isFocused);
        ctx.highlightedLine('$arrow ${entry.label}', highlighted: isFocused);
      },
    );

    if (result == null) return '';
    return selectedPath ?? '';
  }
}

// ════════════════════════════════════════════════════════════════════════════
// INTERNAL HELPERS
// ════════════════════════════════════════════════════════════════════════════

class _Entry {
  final String label;
  final String path;
  final _EntryType type;

  _Entry(this.label, this.path, this.type);
}

enum _EntryType { up, confirmDir, directory, file }

List<_Entry> _readEntries(Directory dir, bool showHidden, bool allowFiles) {
  final List<_Entry> list = [];

  // Parent navigation
  final hasParent = dir.parent.path != dir.path;
  if (hasParent) {
    list.add(_Entry('↩ ..', dir.parent.path, _EntryType.up));
  }

  // Select current directory
  list.add(_Entry('✓ Select this directory', dir.path, _EntryType.confirmDir));

  // List directory contents
  try {
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

    for (final e in filtered) {
      if (e is Directory) {
        list.add(_Entry('▸ ${_basename(e.path)}', e.path, _EntryType.directory));
      } else if (allowFiles && e is File) {
        list.add(_Entry('· ${_basename(e.path)}', e.path, _EntryType.file));
      }
    }
  } catch (_) {
    // Handle permission errors silently
  }

  return list;
}

String _basename(String path) {
  final parts = path.split(Platform.pathSeparator);
  return parts.isEmpty ? path : parts.last;
}
