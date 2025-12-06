import 'dart:io' show sleep;

import '../style/theme.dart';
import '../system/hints.dart';
import '../system/framed_layout.dart';
import '../system/line_builder.dart';
import '../system/prompt_runner.dart';

/// Theme-aware loading spinner with multiple visual styles.
///
/// Styles: dots (braille), bars (rising/falling), arcs (quarter/half circles).
/// Aligned with ThemeDemo borders, accents, and layout.
///
/// Example:
///   LoadingSpinner(
///     'Loading',
///     message: 'Fetching data',
///     style: SpinnerStyle.dots,
///     duration: const Duration(seconds: 2),
///     fps: 14,
///     theme: PromptTheme.pastel,
///   ).run();
class LoadingSpinner {
  final String label;
  final String message;
  final SpinnerStyle style;
  final Duration duration;
  final int fps;
  final PromptTheme theme;

  LoadingSpinner(
    this.label, {
    this.message = 'Loading',
    this.style = SpinnerStyle.dots,
    this.duration = const Duration(seconds: 2),
    this.fps = 12,
    this.theme = PromptTheme.dark,
  }) : assert(fps > 0);

  void run() {
    final styleCfg = theme.style;
    final frames = _framesForStyle(style);
    final int frameMs = (1000 / fps).clamp(12, 200).round();

    String colorForPhase(int i) {
      // Alternate between accent and highlight for gentle pulse
      return (i % 2 == 0) ? theme.accent : theme.highlight;
    }

    void render(RenderOutput out, int frameIndex) {
      // Use centralized line builder for consistent styling
      final lb = LineBuilder(theme);
      final frame = FramedLayout(label, theme: theme);
      final top = frame.top();
      out.writeln('${theme.bold}$top${theme.reset}');

      final spin = frames[frameIndex % frames.length];
      final color = colorForPhase(frameIndex);

      final line = StringBuffer();
      line.write(lb.gutter());
      line.write('${theme.dim}$message${theme.reset}  ');
      line.write('${theme.bold}$color$spin${theme.reset}');
      out.writeln(line.toString());

      if (styleCfg.showBorder) {
        out.writeln(frame.bottom());
      }

      out.writeln(Hints.bullets([
        'Theme-aware spinner',
        'Style: ${style.name}',
      ], theme, dim: true));
    }

    // Use TerminalSession for cursor hiding + RenderOutput for partial clearing
    TerminalSession(hideCursor: true).runWithOutput((out) {
      final sw = Stopwatch()..start();
      int frame = 0;

      // Initial render
      render(out, frame);
      frame++;

      while (sw.elapsed < duration) {
        sleep(Duration(milliseconds: frameMs));
        out.clear();
        render(out, frame);
        frame++;
      }
    }, clearOnEnd: true);
  }

  List<String> _framesForStyle(SpinnerStyle s) {
    switch (s) {
      case SpinnerStyle.dots:
        // Braille spinner frames – smooth, compact
        return const [
          '⠋',
          '⠙',
          '⠹',
          '⠸',
          '⠼',
          '⠴',
          '⠦',
          '⠧',
          '⠇',
          '⠏',
        ];
      case SpinnerStyle.bars:
        // Rising/Falling bar heights
        return const [
          '▁',
          '▂',
          '▃',
          '▄',
          '▅',
          '▆',
          '▇',
          '█',
          '▇',
          '▆',
          '▅',
          '▄',
          '▃',
          '▂',
        ];
      case SpinnerStyle.arcs:
        // Quarter and half arcs
        return const ['◜', '◠', '◝', '◞', '◡', '◟'];
    }
  }
}

enum SpinnerStyle { dots, bars, arcs }
