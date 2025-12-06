import '../style/theme.dart';
import '../system/hints.dart';
import '../system/key_bindings.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

/// HotkeyGuide – displays available shortcuts in a themed frame.
///
/// Aligns with ThemeDemo styling: titled frame, left gutter using the
/// theme's vertical border glyph, and tasteful use of accent/dim colors.
///
/// **Mixins:** Implements [Themeable] for fluent theme configuration:
/// ```dart
/// HotkeyGuide(shortcuts).withPastelTheme().show();
/// ```
class HotkeyGuide with Themeable {
  /// Rows of [keyLabel, action] pairs.
  final List<List<String>> shortcuts;

  /// Visual theme.
  @override
  final PromptTheme theme;

  /// Title shown at the top of the guide.
  final String title;

  /// Optional footer hints under the guide body (dimmed).
  final List<String> footerHints;

  HotkeyGuide(
    this.shortcuts, {
    this.theme = PromptTheme.dark,
    this.title = 'Hotkeys',
    List<String>? footer,
  }) : footerHints = footer ?? const ['Esc or ? to close'];

  @override
  HotkeyGuide copyWithTheme(PromptTheme theme) {
    return HotkeyGuide(
      shortcuts,
      theme: theme,
      title: title,
      footer: footerHints,
    );
  }

  /// Renders the guide to a RenderOutput.
  void _render(RenderOutput out) {
    final widgetFrame = WidgetFrame(
      title: title,
      theme: theme,
      hintStyle: HintStyle.none,
    );

    widgetFrame.render(out, (ctx) {
      final body = Hints.grid(shortcuts, theme).split('\n');
      for (final line in body) {
        ctx.gutterLine(line);
      }

      if (footerHints.isNotEmpty) {
        ctx.gutterLine(Hints.comma(footerHints, theme));
      }
    });
  }

  /// Displays the guide and waits for a close key: Esc, Enter, or '?'.
  void run() {
    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings([
      KeyBinding.multi(
        {KeyEventType.esc, KeyEventType.enter},
        (event) => KeyActionResult.confirmed,
      ),
      KeyBinding.char(
        (c) => c == '?',
        (event) => KeyActionResult.confirmed,
      ),
    ]) + KeyBindings.cancel();

    final runner = PromptRunner(hideCursor: true);
    runner.runWithBindings(
      render: _render,
      bindings: bindings,
    );
  }
}
