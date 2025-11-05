import 'dart:io';

import '../style/theme.dart';
import '../system/frame_renderer.dart';
import '../system/hints.dart';
import '../system/terminal.dart';

/// ProgressDots – animated ellipsis while waiting.
///
/// Aligns with ThemeDemo styling using themed borders, accents,
/// and layout spacing. Designed to be simple and beautiful.
class ProgressDots {
  final String label;
  final String message;
  final int maxDots;
  final Duration duration;
  final Duration interval;
  final PromptTheme theme;

  ProgressDots(
    this.label, {
    this.message = 'Working',
    this.maxDots = 3,
    this.duration = const Duration(seconds: 2),
    this.interval = const Duration(milliseconds: 250),
    this.theme = PromptTheme.dark,
  })  : assert(maxDots > 0),
        assert(!interval.isNegative && interval > Duration.zero);

  /// Run the animated dots for the configured duration.
  void run() {
    final style = theme.style;
    final term = Terminal.enterRaw();
    Terminal.hideCursor();

    void cleanup() {
      term.restore();
      Terminal.showCursor();
    }

    final sw = Stopwatch()..start();
    int phase = 0;

    void render() {
      Terminal.clearAndHome();

      final top = style.showBorder
          ? FrameRenderer.titleWithBorders(label, theme)
          : FrameRenderer.plainTitle(label, theme);
      stdout.writeln('${theme.bold}$top${theme.reset}');

      final dots = '.' * ((phase % (maxDots + 1)));
      final line = StringBuffer();
      line.write('${theme.gray}${style.borderVertical}${theme.reset} ');
      line.write('${theme.dim}$message${theme.reset} ');
      line.write('${theme.accent}$dots${theme.reset}');
      stdout.writeln(line.toString());

      if (style.showBorder) {
        stdout.writeln(FrameRenderer.bottomLine(label, theme));
      }

      stdout.writeln(Hints.bullets([
        'Animated ellipsis',
        'Theme-aligned borders',
      ], theme, dim: true));
    }

    try {
      while (sw.elapsed < duration) {
        render();
        phase++;
        sleep(interval);
      }
    } finally {
      cleanup();
    }

    Terminal.clearAndHome();
  }
}

/// Convenience function mirroring the requested API shape.
void progressDots(
  String label, {
  String message = 'Working',
  int maxDots = 3,
  Duration duration = const Duration(seconds: 2),
  Duration interval = const Duration(milliseconds: 250),
  PromptTheme theme = PromptTheme.dark,
}) {
  ProgressDots(
    label,
    message: message,
    maxDots: maxDots,
    duration: duration,
    interval: interval,
    theme: theme,
  ).run();
}
