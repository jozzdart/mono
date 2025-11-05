import 'dart:io';

import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/terminal.dart';

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

  /// Renders the guide once to stdout (no input handling).
  void show() {
    final style = theme.style;

    final frame = FramedLayout(title, theme: theme);
    stdout.writeln('${theme.bold}${frame.top()}${theme.reset}');

    final body = Hints.grid(shortcuts, theme).split('\n');
    for (final line in body) {
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} $line');
    }

    if (footerHints.isNotEmpty) {
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} ${Hints.comma(footerHints, theme)}');
    }

    final bottom = frame.bottom();
    stdout.writeln(bottom);
  }

  /// Displays the guide and waits for a close key: Esc, Enter, or '?'.
  void run() {
    final term = Terminal.enterRaw();
    Terminal.hideCursor();
    try {
      Terminal.clearAndHome();
      show();
      while (true) {
        final ev = KeyEventReader.read();
        if (ev.type == KeyEventType.esc ||
            ev.type == KeyEventType.enter ||
            (ev.type == KeyEventType.char && ev.char == '?') ||
            ev.type == KeyEventType.ctrlC) {
          break;
        }
      }
    } finally {
      term.restore();
      Terminal.showCursor();
    }
  }
}


