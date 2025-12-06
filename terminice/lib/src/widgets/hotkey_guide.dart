import '../style/theme.dart';
import '../system/hints.dart';
import '../system/key_bindings.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

/// HotkeyGuide – displays available shortcuts in a themed frame.
///
/// Aligns with ThemeDemo styling: titled frame, left gutter using the
/// theme's vertical border glyph, and tasteful use of accent/dim colors.
class HotkeyGuide {
  /// Rows of [keyLabel, action] pairs.
  final List<List<String>> shortcuts;

  /// Visual theme.
  final PromptTheme theme;

  /// Title shown at the top of the guide.
  final String title;

  /// Optional footer hints under the guide body (dimmed).
  final List<String> footerHints;

  HotkeyGuide(
    this.shortcuts, {
    this.theme = const PromptTheme(),
    this.title = 'Hotkeys',
    List<String>? footer,
  }) : footerHints = footer ?? const ['Esc or ? to close'];

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
