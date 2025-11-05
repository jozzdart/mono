import 'dart:io';

import '../style/theme.dart';
import 'search_select.dart';
import '../system/terminal.dart';
import '../system/key_events.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';

/// A simple interactive demo to iterate through themes
/// and preview how they affect the prompt appearance.
///
/// Controls:
/// ↑ / ↓ - move between themes
/// Enter - apply / preview
/// Esc - exit
class ThemeDemo {
  final Map<String, PromptTheme> themes;

  ThemeDemo({
    Map<String, PromptTheme>? customThemes,
  }) : themes = customThemes ??
            {
              'Dark': PromptTheme.dark,
              'Matrix': PromptTheme.matrix,
              'Fire': PromptTheme.fire,
              'Pastel': PromptTheme.pastel,
            };

  void run() {
    final themeNames = themes.keys.toList();

    String selected = themeNames.first;
    int selectedIndex = 0;

    final term = Terminal.enterRaw();

    void cleanup() {
      term.restore();
      stdout.write('\x1B[?25h');
    }

    void renderThemePreview(String name, PromptTheme theme) {
      final style = theme.style;
      Terminal.clearAndHome();

      final frame = FramedLayout('Theme Preview', theme: theme);
      stdout.writeln('${theme.bold}${frame.top()}${theme.reset}');
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} Theme: ${theme.accent}$name${theme.reset}');
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} Arrow: ${theme.accent}${style.arrow}${theme.reset}');
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} Checkbox: ${theme.checkboxOn}${style.checkboxOnSymbol}${theme.reset} / ${theme.checkboxOff}${style.checkboxOffSymbol}${theme.reset}');
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} Border: ${theme.selection}${style.borderTop}${style.borderConnector}${style.borderBottom}${theme.reset}');
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} Highlight: ${theme.highlight}Highlight text${theme.reset}');
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} Inverse: ${theme.inverse} Inverted line ${theme.reset}');
      stdout.writeln(
          '${theme.gray}${style.borderBottom}${'─' * 25}${theme.reset}');
      stdout.writeln(Hints.bullets([
        '↑↓ to browse',
        'Enter to preview prompt',
        'Esc to exit',
      ], theme, dim: true));
    }

    try {
      while (true) {
        renderThemePreview(selected, themes[selected]!);
        final ev = KeyEventReader.read();

        // ESC
        if (ev.type == KeyEventType.esc) {
          break;
        } else if (ev.type == KeyEventType.arrowUp) {
          selectedIndex =
              (selectedIndex - 1 + themeNames.length) % themeNames.length;
          selected = themeNames[selectedIndex];
        } else if (ev.type == KeyEventType.arrowDown) {
          selectedIndex = (selectedIndex + 1) % themeNames.length;
          selected = themeNames[selectedIndex];
        }

        // Enter
        else if (ev.type == KeyEventType.enter) {
          final fruits = [
            'apple',
            'banana',
            'cherry',
            'date',
            'fig',
            'grape',
            'lemon',
            'mango',
            'pear',
            'plum',
          ];
          final prompt = SearchSelectPrompt(
            fruits,
            prompt: 'Previewing theme: $selected',
            multiSelect: true,
            theme: themes[selected]!,
          );
          prompt.run();
        }

        // Ctrl+C
        else if (ev.type == KeyEventType.ctrlC) {
          break;
        }
      }
    } finally {
      cleanup();
    }
  }
}
