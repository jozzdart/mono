import 'dart:io';

import '../style/theme.dart';
import '../system/terminal.dart';
import '../system/frame_renderer.dart';
import '../system/hints.dart';

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

    final term = Terminal.enterRaw();
    Terminal.hideCursor();

    void cleanup() {
      term.restore();
      Terminal.showCursor();
    }

    final sw = Stopwatch()..start();

    String colorForPhase(int i) {
      // Alternate between accent and highlight for gentle pulse
      return (i % 2 == 0) ? theme.accent : theme.highlight;
    }

    void render(int frameIndex) {
      Terminal.clearAndHome();

      final top = styleCfg.showBorder
          ? FrameRenderer.titleWithBorders(label, theme)
          : FrameRenderer.plainTitle(label, theme);
      stdout.writeln('${theme.bold}$top${theme.reset}');

      final spin = frames[frameIndex % frames.length];
      final color = colorForPhase(frameIndex);

      final line = StringBuffer();
      line.write('${theme.gray}${styleCfg.borderVertical}${theme.reset} ');
      line.write('${theme.dim}$message${theme.reset}  ');
      line.write('${theme.bold}$color$spin${theme.reset}');
      stdout.writeln(line.toString());

      if (styleCfg.showBorder) {
        stdout.writeln(FrameRenderer.bottomLine(label, theme));
      }

      stdout.writeln(Hints.bullets([
        'Theme-aware spinner',
        'Style: ${style.name}',
      ], theme, dim: true));
    }

    try {
      int frame = 0;
      while (sw.elapsed < duration) {
        render(frame);
        frame++;
        sleep(Duration(milliseconds: frameMs));
      }
    } finally {
      cleanup();
    }

    Terminal.clearAndHome();
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
