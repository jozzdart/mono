import 'dart:io' show sleep;

import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/line_builder.dart';
import '../system/prompt_runner.dart';

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

    void render(RenderOutput out, int phase) {
      // Use centralized line builder for consistent styling
      final lb = LineBuilder(theme);

      final frame = FramedLayout(label, theme: theme);
      final top = frame.top();
      out.writeln('${theme.bold}$top${theme.reset}');

      final dots = '.' * ((phase % (maxDots + 1)));
      final line = StringBuffer();
      line.write(lb.gutter());
      line.write('${theme.dim}$message${theme.reset} ');
      line.write('${theme.accent}$dots${theme.reset}');
      out.writeln(line.toString());

      if (style.showBorder) {
        out.writeln(frame.bottom());
      }

      out.writeln(Hints.bullets([
        'Animated ellipsis',
        'Theme-aligned borders',
      ], theme, dim: true));
    }

    // Use TerminalSession for cursor hiding + RenderOutput for partial clearing
    TerminalSession(hideCursor: true).runWithOutput((out) {
      final sw = Stopwatch()..start();
      int phase = 0;

      // Initial render
      render(out, phase);
      phase++;

      while (sw.elapsed < duration) {
        sleep(interval);
        out.clear();
        render(out, phase);
        phase++;
      }
    }, clearOnEnd: true);
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
