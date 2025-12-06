import '../style/theme.dart';
import 'search_select.dart';
import '../system/focus_navigation.dart';
import '../system/key_bindings.dart';
import '../system/hints.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

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

    // Use centralized focus navigation
    final focus = FocusNavigation(itemCount: themeNames.length);
    String selected = themeNames.first;
    bool showPromptPreview = false;

    void renderThemePreview(RenderOutput out, String name, PromptTheme theme) {
      final style = theme.style;

      final widgetFrame = WidgetFrame(
        title: 'Theme Preview',
        theme: theme,
        hintStyle: HintStyle.none,
      );

      widgetFrame.render(out, (ctx) {
        ctx.labeledAccent('Theme', name);
        ctx.gutterLine('Arrow: ${theme.accent}${style.arrow}${theme.reset}');
        ctx.gutterLine(
            'Checkbox: ${theme.checkboxOn}${style.checkboxOnSymbol}${theme.reset} / ${theme.checkboxOff}${style.checkboxOffSymbol}${theme.reset}');
        ctx.gutterLine(
            'Border: ${theme.selection}${style.borderTop}${style.borderConnector}${style.borderBottom}${theme.reset}');
        ctx.gutterLine('Highlight: ${theme.highlight}Highlight text${theme.reset}');
        ctx.gutterLine('Inverse: ${theme.inverse} Inverted line ${theme.reset}');
      });

      out.writeln(
          '${theme.gray}${style.borderBottom}${'─' * 25}${theme.reset}');
      out.writeln(Hints.bullets([
        '↑↓ to browse',
        'Enter to preview prompt',
        'Esc to exit',
      ], theme, dim: true));
    }

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings.verticalNavigation(
          onUp: () {
            focus.moveUp();
            selected = themeNames[focus.focusedIndex];
          },
          onDown: () {
            focus.moveDown();
            selected = themeNames[focus.focusedIndex];
          },
        ) +
        KeyBindings.confirm(onConfirm: () {
          showPromptPreview = true;
          return KeyActionResult.confirmed;
        }) +
        KeyBindings.cancel();

    final runner = PromptRunner(hideCursor: true);
    runner.runWithBindings(
      render: (out) => renderThemePreview(out, selected, themes[selected]!),
      bindings: bindings,
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
