import 'dart:io';

import '../style/theme.dart';
import '../system/frame_renderer.dart';
import '../system/key_events.dart';
import '../system/terminal.dart';
import '../system/hints.dart';
import 'text_prompt.dart';
import 'confirm_prompt.dart';
import 'search_select.dart';

/// EnvManager – view/edit environment variables.
///
/// Aligns with ThemeDemo styling:
/// - Themed title bar and bottom border
/// - Left gutter uses the theme's vertical border glyph
/// - Tasteful use of accent/highlight colors
class EnvManager {
  final PromptTheme theme;
  final String? title;
  final Map<String, String>? initialEnv;

  EnvManager({
    this.theme = const PromptTheme(),
    this.title,
    this.initialEnv,
  });

  Future<void> run() async {
    final label = title ?? 'Env Manager';

    // Working set (in-memory)
    var entries = _toEntries(initialEnv ?? Platform.environment);

    bool quit = false;
    while (!quit) {
      // If no variables, offer to create one first
      if (entries.isEmpty) {
        await _add(entries);
        if (entries.isEmpty) break; // user cancelled
      }

      // Use existing SearchSelectPrompt for selection & filtering
      final names = entries.map((e) => e.name).toList(growable: false);
      final selection = SearchSelectPrompt(
        names,
        prompt: label,
        showSearch: true,
        maxVisible: 12,
        theme: theme,
      ).run();

      if (selection.isEmpty) break; // cancelled → exit
      final selectedName = selection.first;

      // Actions screen for the selected variable
      final action = await _actionsLoop(selectedName, () => entries);
      if (action == _PostAction.quit) {
        quit = true;
      } else if (action == _PostAction.reload) {
        entries = _toEntries(Platform.environment);
      }
      // On back/delete/edit/new we simply loop to selection again
    }

    Terminal.clearAndHome();
  }

  Future<_PostAction> _actionsLoop(
      String name, List<_EnvEntry> Function() getEntries) async {
    final style = theme.style;
    String currentName = name;
    var entries = getEntries();

    void render() {
      Terminal.clearAndHome();
      final heading = 'Env · $currentName';
      final top = style.showBorder
          ? FrameRenderer.titleWithBorders(heading, theme)
          : FrameRenderer.plainTitle(heading, theme);
      stdout.writeln('${theme.bold}$top${theme.reset}');

      final entry = entries.firstWhere(
        (e) => e.name == currentName,
        orElse: () => _EnvEntry(currentName, ''),
      );

      stdout.writeln('${theme.gray}${style.borderVertical}${theme.reset} '
          '${theme.dim}Name:${theme.reset} ${theme.accent}${entry.name}${theme.reset}');
      final value = entry.value.isEmpty
          ? '${theme.dim}<empty>${theme.reset}'
          : entry.value;
      stdout.writeln('${theme.gray}${style.borderVertical}${theme.reset} '
          '${theme.dim}Value:${theme.reset} $value');

      if (style.showBorder) {
        stdout.writeln(FrameRenderer.bottomLine(heading, theme));
      }

      stdout.writeln(Hints.grid([
        ['Enter / e', 'edit value'],
        ['d', 'delete variable'],
        ['n', 'new variable'],
        ['b', 'back to list'],
        ['Ctrl+R', 'reload from system'],
        ['q / Esc', 'quit'],
      ], theme));
    }

    // Enter raw mode for action loop
    final term = Terminal.enterRaw();
    Terminal.hideCursor();
    render();
    try {
      while (true) {
        final ev = KeyEventReader.read();

        // Quit
        if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
          return _PostAction.quit;
        }
        if (ev.type == KeyEventType.char &&
            (ev.char == 'q' || ev.char == 'Q')) {
          return _PostAction.quit;
        }

        // Back to list
        if (ev.type == KeyEventType.char &&
            (ev.char == 'b' || ev.char == 'B')) {
          return _PostAction.back;
        }

        // Reload
        if (ev.type == KeyEventType.ctrlR) {
          return _PostAction.reload;
        }

        // Edit (Enter or 'e')
        if (ev.type == KeyEventType.enter ||
            (ev.type == KeyEventType.char &&
                (ev.char == 'e' || ev.char == 'E'))) {
          final entry = entries.firstWhere(
            (e) => e.name == currentName,
            orElse: () => _EnvEntry(currentName, ''),
          );
          final newVal = await TextPrompt(
            prompt: 'Edit ${entry.name}',
            placeholder: entry.value,
            theme: theme,
            required: false,
          ).run();
          if (newVal != null) {
            _setEntry(entries, entry.name, newVal);
          }
          render();
          continue;
        }

        // Delete
        if (ev.type == KeyEventType.char &&
            (ev.char == 'd' || ev.char == 'D')) {
          final ok = ConfirmPrompt(
            label: 'Delete Variable',
            message: 'Delete $currentName?',
            yesLabel: 'Delete',
            noLabel: 'Cancel',
            theme: theme,
            defaultYes: false,
          ).run();
          if (ok) {
            entries.removeWhere((e) => e.name == currentName);
            return _PostAction.back; // go back to list after deletion
          }
          render();
          continue;
        }

        // New variable
        if (ev.type == KeyEventType.char &&
            (ev.char == 'n' || ev.char == 'N')) {
          await _add(entries);
          render();
          continue;
        }
      }
    } finally {
      term.restore();
      Terminal.showCursor();
    }
  }

  Future<void> _add(List<_EnvEntry> entries) async {
    final name = await TextPrompt(
      prompt: 'New variable name',
      placeholder: 'NAME',
      theme: theme,
      required: true,
      validator: (s) {
        final v = s.trim();
        if (v.isEmpty) return 'Name cannot be empty.';
        if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(v)) {
          return 'Use letters, digits, and underscore (not starting with digit).';
        }
        return '';
      },
    ).run();
    if (name == null) return;

    // If exists, confirm overwrite
    final exists = entries.any((e) => e.name == name);
    if (exists) {
      final ok = ConfirmPrompt(
        label: 'Overwrite Variable',
        message: '$name exists. Overwrite value?',
        yesLabel: 'Overwrite',
        noLabel: 'Cancel',
        theme: theme,
        defaultYes: false,
      ).run();
      if (!ok) return;
    }

    final value = await TextPrompt(
      prompt: 'Value for $name',
      placeholder: '',
      theme: theme,
      required: false,
    ).run();
    if (value == null) return;
    _setEntry(entries, name, value);
  }

  void _setEntry(List<_EnvEntry> entries, String name, String value) {
    final idx = entries.indexWhere((e) => e.name == name);
    if (idx >= 0) {
      entries[idx] = _EnvEntry(name, value);
    } else {
      entries.add(_EnvEntry(name, value));
      entries.sort((a, b) => a.name.compareTo(b.name));
    }
  }

  List<_EnvEntry> _toEntries(Map<String, String> env) {
    final list = env.entries
        .map((e) => _EnvEntry(e.key, e.value))
        .toList(growable: true);
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }
}

class _EnvEntry {
  final String name;
  final String value;
  _EnvEntry(this.name, this.value);
}

enum _PostAction { back, reload, quit }

/// Convenience function mirroring the requested API name.
Future<void> envManager({
  PromptTheme theme = const PromptTheme(),
  String? title,
  Map<String, String>? initialEnv,
}) async {
  await EnvManager(theme: theme, title: title, initialEnv: initialEnv).run();
}
