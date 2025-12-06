import 'dart:io';

import '../style/theme.dart';
import '../system/key_bindings.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';
import 'text_prompt.dart';
import 'confirm_prompt.dart';
import 'search_select.dart';

/// EnvManager – view/edit environment variables.
///
/// Aligns with ThemeDemo styling:
/// - Themed title bar and bottom border
/// - Left gutter uses the theme's vertical border glyph
/// - Tasteful use of accent/highlight colors
///
/// **Mixins:** Implements [Themeable] for fluent theme configuration:
/// ```dart
/// EnvManager().withMatrixTheme().run();
/// ```
class EnvManager with Themeable {
  @override
  final PromptTheme theme;
  final String? title;
  final Map<String, String>? initialEnv;

  EnvManager({
    this.theme = PromptTheme.dark,
    this.title,
    this.initialEnv,
  });

  @override
  EnvManager copyWithTheme(PromptTheme theme) {
    return EnvManager(
      theme: theme,
      title: title,
      initialEnv: initialEnv,
    );
  }

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
    // Note: No full terminal clear - PromptRunner handles cleanup and preserves terminal history
  }

  Future<_PostAction> _actionsLoop(
      String name, List<_EnvEntry> Function() getEntries) async {
    String currentName = name;
    var entries = getEntries();
    _PostAction result = _PostAction.back;
    bool needsNestedPrompt = false;
    String? nestedPromptType;

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings([
          // Edit (Enter or 'e')
          KeyBinding.multi(
            {KeyEventType.enter},
            (event) {
              needsNestedPrompt = true;
              nestedPromptType = 'edit';
              return KeyActionResult.confirmed;
            },
            hintLabel: 'Enter / e',
            hintDescription: 'edit value',
          ),
          KeyBinding.char(
            (c) => c == 'e' || c == 'E',
            (event) {
              needsNestedPrompt = true;
              nestedPromptType = 'edit';
              return KeyActionResult.confirmed;
            },
          ),
          // Delete
          KeyBinding.char(
            (c) => c == 'd' || c == 'D',
            (event) {
              needsNestedPrompt = true;
              nestedPromptType = 'delete';
              return KeyActionResult.confirmed;
            },
            hintLabel: 'd',
            hintDescription: 'delete variable',
          ),
          // New variable
          KeyBinding.char(
            (c) => c == 'n' || c == 'N',
            (event) {
              needsNestedPrompt = true;
              nestedPromptType = 'new';
              return KeyActionResult.confirmed;
            },
            hintLabel: 'n',
            hintDescription: 'new variable',
          ),
          // Back to list
          KeyBinding.char(
            (c) => c == 'b' || c == 'B',
            (event) {
              result = _PostAction.back;
              return KeyActionResult.confirmed;
            },
            hintLabel: 'b',
            hintDescription: 'back to list',
          ),
        ]) +
        KeyBindings.ctrlR(
          onPress: () => result = _PostAction.reload,
          hintDescription: 'reload from system',
        ) +
        KeyBindings([
          // Quit
          KeyBinding.char(
            (c) => c == 'q' || c == 'Q',
            (event) {
              result = _PostAction.quit;
              return KeyActionResult.confirmed;
            },
            hintLabel: 'q / Esc',
            hintDescription: 'quit',
          ),
        ]) +
        KeyBindings.cancel(onCancel: () => result = _PostAction.quit);

    void render(RenderOutput out) {
      final heading = 'Env · $currentName';
      final widgetFrame = WidgetFrame(
        title: heading,
        theme: theme,
        bindings: bindings,
        hintStyle: HintStyle.grid,
      );

      widgetFrame.render(out, (ctx) {
        final entry = entries.firstWhere(
          (e) => e.name == currentName,
          orElse: () => _EnvEntry(currentName, ''),
        );

        ctx.labeledAccent('Name', entry.name);
        final value =
            entry.value.isEmpty ? '${theme.dim}<empty>${theme.reset}' : entry.value;
        ctx.labeledValue('Value', value);
      });
    }

    while (true) {
      needsNestedPrompt = false;
      nestedPromptType = null;

      final runner = PromptRunner(hideCursor: true);
      runner.runWithBindings(
        render: render,
        bindings: bindings,
      );

      // Handle nested prompts outside of the runner
      if (needsNestedPrompt) {
        if (nestedPromptType == 'edit') {
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
          continue; // Loop back to show actions again
        }

        if (nestedPromptType == 'delete') {
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
          continue; // Loop back to show actions again
        }

        if (nestedPromptType == 'new') {
          await _add(entries);
          continue; // Loop back to show actions again
        }
      }

      // No nested prompt - we have a final result
      return result;
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
