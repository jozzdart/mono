import 'dart:io';
import '../style/theme.dart';
import 'search_select.dart';

/// FilePickerPrompt – reuses SearchSelectPrompt for navigation & search.
/// Fully responsive, instant, zero-delay.
class FilePickerPrompt {
  final String label;
  final PromptTheme theme;
  final Directory startDir;
  final bool showHidden;
  final bool foldersOnly;

  FilePickerPrompt({
    required this.label,
    this.theme = PromptTheme.dark,
    Directory? startDir,
    this.showHidden = false,
    this.foldersOnly = false,
  }) : startDir = startDir ?? Directory.current;

  String run() {
    Directory current = startDir;

    while (true) {
      // Read directory entries
      final entries = _readEntries(current);
      final names = entries.map((e) {
        final isDir = e is Directory;
        final icon = isDir ? '▸' : '·';
        final name = _basename(e.path);
        return '$icon $name';
      }).toList();

      // Add a "go up" entry if not root
      if (current.parent.path != current.path) {
        names.insert(0, '↩ ..');
      }

      // Use shared search/select prompt
      final select = SearchSelectPrompt(
        names,
        prompt: '${label} (${_shortPath(current.path)})',
        showSearch: true,
        multiSelect: false,
        maxVisible: 15,
        theme: theme,
      );

      final result = select.run();
      if (result.isEmpty) return '';

      final choice = result.first;

      // Handle ".." navigation
      if (choice.startsWith('↩')) {
        current = current.parent;
        continue;
      }

      // Map back to entity
      final idx = names.indexOf(choice);
      final entity = (current.parent.path != current.path)
          ? entries[idx - 1]
          : entries[idx];

      if (entity is Directory) {
        current = entity;
        continue;
      } else if (!foldersOnly && entity is File) {
        return entity.path;
      }
    }
  }

  // ────────────────────────── Helpers ──────────────────────────
  List<FileSystemEntity> _readEntries(Directory dir) {
    final all = dir.listSync(followLinks: false);
    all.sort((a, b) {
      final aDir = a is Directory;
      final bDir = b is Directory;
      if (aDir != bDir) return aDir ? -1 : 1;
      return _basename(a.path)
          .toLowerCase()
          .compareTo(_basename(b.path).toLowerCase());
    });
    return all
        .where((e) => showHidden || !_basename(e.path).startsWith('.'))
        .toList();
  }

  String _basename(String path) {
    final parts = path.split(Platform.pathSeparator);
    return parts.isEmpty ? path : parts.last;
  }

  String _shortPath(String path) {
    return path.length > 60 ? '...${path.substring(path.length - 57)}' : path;
  }
}
