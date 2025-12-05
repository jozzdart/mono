import '../style/theme.dart';
import 'search_select.dart';
import '../system/key_events.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/prompt_runner.dart';

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
    bool showPromptPreview = false;

    void renderThemePreview(RenderOutput out, String name, PromptTheme theme) {
      final style = theme.style;

      final frame = FramedLayout('Theme Preview', theme: theme);
      out.writeln('${theme.bold}${frame.top()}${theme.reset}');
      out.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} Theme: ${theme.accent}$name${theme.reset}');
      out.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} Arrow: ${theme.accent}${style.arrow}${theme.reset}');
      out.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} Checkbox: ${theme.checkboxOn}${style.checkboxOnSymbol}${theme.reset} / ${theme.checkboxOff}${style.checkboxOffSymbol}${theme.reset}');
      out.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} Border: ${theme.selection}${style.borderTop}${style.borderConnector}${style.borderBottom}${theme.reset}');
      out.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} Highlight: ${theme.highlight}Highlight text${theme.reset}');
      out.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} Inverse: ${theme.inverse} Inverted line ${theme.reset}');
      out.writeln(
          '${theme.gray}${style.borderBottom}${'─' * 25}${theme.reset}');
      out.writeln(Hints.bullets([
        '↑↓ to browse',
        'Enter to preview prompt',
        'Esc to exit',
      ], theme, dim: true));
    }

    final runner = PromptRunner(hideCursor: true);
    runner.run(
      render: (out) => renderThemePreview(out, selected, themes[selected]!),
      onKey: (ev) {
        // ESC
        if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
          return PromptResult.cancelled;
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
          showPromptPreview = true;
          return PromptResult.confirmed;
        }

        return null;
      },
    );

    if (showPromptPreview) {
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
  }
}
