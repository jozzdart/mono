import 'dart:io' show sleep;

import '../style/prompt_config.dart';
import '../style/theme.dart';
import '../system/hints.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

/// Theme-aware loading spinner with multiple visual styles.
///
/// Styles: dots (braille), bars (rising/falling), arcs (quarter/half circles).
/// Aligned with ThemeDemo borders, accents, and layout.
///
/// **Configuration:** Supports both direct theme and [PromptConfig]:
/// ```dart
/// // Fluent API
/// LoadingSpinner('Loading').withPastelTheme().run();
///
/// // With shared config
/// final config = PromptConfig.pastel;
/// LoadingSpinner('Loading', config: config).run();
/// ```
class LoadingSpinner with Themeable {
  final String label;
  final String message;
  final SpinnerStyle style;
  final Duration duration;
  final int fps;
  @override
  final PromptTheme theme;

  /// Creates a loading spinner.
  ///
  /// Accepts either:
  /// - A [PromptConfig] object (theme extracted automatically)
  /// - A direct [theme] parameter (for convenience)
  LoadingSpinner(
    this.label, {
    this.message = 'Loading',
    this.style = SpinnerStyle.dots,
    this.duration = const Duration(seconds: 2),
    this.fps = 12,
    // Config object (preferred for shared configuration)
    PromptConfig? config,
    // Direct theme (for convenience)
    PromptTheme theme = PromptTheme.dark,
  })  : theme = config?.theme ?? theme,
        assert(fps > 0);

  @override
  LoadingSpinner copyWithTheme(PromptTheme theme) {
    return LoadingSpinner(
      label,
      message: message,
      style: style,
      duration: duration,
      fps: fps,
      theme: theme,
    );
  }

  void run() {
    final frames = _framesForStyle(style);
    final int frameMs = (1000 / fps).clamp(12, 200).round();

    String colorForPhase(int i) {
      // Alternate between accent and highlight for gentle pulse
      return (i % 2 == 0) ? theme.accent : theme.highlight;
    }

    void render(RenderOutput out, int frameIndex) {
      final widgetFrame = WidgetFrame(title: label, theme: theme);
      widgetFrame.showTo(out, (ctx) {
        final spin = frames[frameIndex % frames.length];
        final color = colorForPhase(frameIndex);
        ctx.gutterLine(
            '${theme.dim}$message${theme.reset}  ${theme.bold}$color$spin${theme.reset}');
      });

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
