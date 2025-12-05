import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/prompt_runner.dart';

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
    final style = theme.style;

    final frame = FramedLayout(title, theme: theme);
    out.writeln('${theme.bold}${frame.top()}${theme.reset}');

    final body = Hints.grid(shortcuts, theme).split('\n');
    for (final line in body) {
      out.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} $line');
    }

    if (footerHints.isNotEmpty) {
      out.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} ${Hints.comma(footerHints, theme)}');
    }

    final bottom = frame.bottom();
    out.writeln(bottom);
  }

  /// Displays the guide and waits for a close key: Esc, Enter, or '?'.
  void run() {
    final runner = PromptRunner(hideCursor: true);
    runner.run(
      render: _render,
      onKey: (ev) {
        if (ev.type == KeyEventType.esc ||
            ev.type == KeyEventType.enter ||
            (ev.type == KeyEventType.char && ev.char == '?') ||
            ev.type == KeyEventType.ctrlC) {
          return PromptResult.confirmed;
        }
        return null;
      },
    );
  }
}
