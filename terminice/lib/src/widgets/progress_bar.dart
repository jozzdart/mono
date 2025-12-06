import 'dart:io' show sleep;
import 'dart:math' as math;

import '../style/theme.dart';
import '../system/hints.dart';
import '../system/prompt_animations.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

/// Animated, colorful progress bar aligned with ThemeDemo styling.
///
/// Features:
/// - Title with themed borders
/// - Smooth auto-advance animation
/// - Shimmering head and subtle gradient fill
/// - Percent, elapsed and ETA
///
/// **Mixins:** Implements [Themeable] for fluent theme configuration:
/// ```dart
/// ProgressBar('Downloading').withMatrixTheme().run();
/// ```
///
/// Usage:
///   ProgressBar('Downloading', total: 120, width: 40).run();
class ProgressBar with Themeable {
  final String label;
  final int total; // logical steps to complete
  final int width; // visual bar width
  final Duration? totalDuration; // optional target duration for full progress
  @override
  final PromptTheme theme;

  ProgressBar(
    this.label, {
    this.total = 100,
    this.width = 36,
    this.totalDuration,
    this.theme = PromptTheme.dark,
  })  : assert(total > 0),
        assert(width > 4);

  @override
  ProgressBar copyWithTheme(PromptTheme theme) {
    return ProgressBar(
      label,
      total: total,
      width: width,
      totalDuration: totalDuration,
      theme: theme,
    );
  }

  void run() {
    final Duration target = totalDuration ?? const Duration(milliseconds: 2200);

    // Use TerminalSession for cursor hiding + RenderOutput for partial clearing
    TerminalSession(hideCursor: true).runWithOutput((out) {
      // Timing model
      final stopwatch = Stopwatch()..start();

      // Render a single frame for a given progress [0..total]
      void render(int current, {int shimmerPhase = 0}) {
        final widgetFrame = WidgetFrame(title: label, theme: theme);
        widgetFrame.showTo(out, (ctx) {
          // Compute
          final ratio = current / total;
          final filled = (ratio * width).clamp(0, width).round();
          final percent = (ratio * 100).clamp(0, 100).round();

          // Build gradient fill with a moving shimmer head
          final buffer = StringBuffer();
          for (int i = 0; i < width; i++) {
            final isFilled = i < filled;
            if (!isFilled) {
              buffer.write('${theme.dim}·${theme.reset}');
              continue;
            }

            // Shimmer: bright head traversing the filled segment
            // Move the head across with a triangular pulse around (filled-1)
            final headPos = filled - 1;
            final distance = (i - headPos).abs();
            final headGlow = (3 - distance).clamp(0, 3); // 0..3

            // Color cycling between accent and highlight with a subtle phase shift
            final cycle = ((i + shimmerPhase) % 6);
            final baseColor = (cycle < 3) ? theme.accent : theme.highlight;

            // Shade set for density illusion
            const shades = ['░', '▒', '▓', '█'];
            final ch = shades[(headGlow).clamp(0, 3)];

            // Head gets bold/inverse to pop
            if (i == headPos) {
              buffer.write('${theme.inverse}$baseColor$ch${theme.reset}');
            } else if (headGlow > 0) {
              buffer.write('${theme.bold}$baseColor$ch${theme.reset}');
            } else {
              buffer.write('$baseColor$ch${theme.reset}');
            }
          }

          ctx.gutterLine(buffer.toString());

          // Second line with metrics: percent, elapsed, ETA
          final elapsed = stopwatch.elapsed;
          final estEta = _eta(elapsed, ratio, target);
          ctx.gutterLine(
              '${theme.dim}Progress:${theme.reset} ${theme.accent}$percent%${theme.reset}   '
              '${theme.dim}Elapsed:${theme.reset} ${_fmt(elapsed)}   ${theme.dim}ETA:${theme.reset} ${_fmt(estEta)}');
        });

        // Hints (non-interactive, just informational)
        out.writeln(Hints.bullets([
          'Animated progress bar',
          'Theme-aware accents',
        ], theme, dim: true));
      }

      // Entry animation: quick grow from 0 to a small head-start
      for (int i = 0; i <= math.min(6, width ~/ 6); i++) {
        out.clear();
        render((total * (i / math.max(1, width))).round(), shimmerPhase: i);
        sleep(const Duration(milliseconds: 10));
      }

      // Main advance loop — ties steps to the target duration
      int current = 0;
      while (current < total) {
        final t = stopwatch.elapsed.inMilliseconds / target.inMilliseconds;
        final eased = Easing.easeInOutCubic(t.clamp(0.0, 1.0));
        final next = (eased * total).clamp(0, total.toDouble()).round();
        if (next > current) current = next;

        final phase = (stopwatch.elapsedMilliseconds ~/ 50) % 1000;
        out.clear();
        render(current, shimmerPhase: phase);

        // Small frame delay; high-ish FPS for smooth shimmer
        sleep(const Duration(milliseconds: 24));
      }

      // Completion flourish — a few shimmering frames
      for (int i = 0; i < 4; i++) {
        out.clear();
        render(total, shimmerPhase: i * 2);
        sleep(const Duration(milliseconds: 30));
      }
    }, clearOnEnd: true);
  }
}

Duration _eta(Duration elapsed, double ratio, Duration target) {
  if (ratio <= 0) return target;
  final remaining = (target * (1 - ratio));
  // Clamp: never negative
  return remaining.isNegative ? Duration.zero : remaining;
}

String _fmt(Duration d) {
  final m = d.inMinutes.remainder(600).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}
