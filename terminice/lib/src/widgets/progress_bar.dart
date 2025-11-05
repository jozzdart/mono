import 'dart:io';
import 'dart:math' as math;

import '../style/theme.dart';
import '../system/terminal.dart';
import '../system/frame_renderer.dart';
import '../system/hints.dart';

/// Animated, colorful progress bar aligned with ThemeDemo styling.
///
/// Features:
/// - Title with themed borders
/// - Smooth auto-advance animation
/// - Shimmering head and subtle gradient fill
/// - Percent, elapsed and ETA
///
/// Usage:
///   ProgressBar('Downloading', total: 120, width: 40).run();
class ProgressBar {
  final String label;
  final int total; // logical steps to complete
  final int width; // visual bar width
  final Duration? totalDuration; // optional target duration for full progress
  final PromptTheme theme;

  ProgressBar(
    this.label, {
    this.total = 100,
    this.width = 36,
    this.totalDuration,
    this.theme = PromptTheme.dark,
  })  : assert(total > 0),
        assert(width > 4);

  void run() {
    final style = theme.style;

    final term = Terminal.enterRaw();
    Terminal.hideCursor();

    void cleanup() {
      term.restore();
      Terminal.showCursor();
    }

    // Timing model
    final stopwatch = Stopwatch()..start();
    final Duration target = totalDuration ?? const Duration(milliseconds: 2200);

    // Render a single frame for a given progress [0..total]
    void render(int current, {int shimmerPhase = 0}) {
      Terminal.clearAndHome();

      // Top line
      final top = style.showBorder
          ? FrameRenderer.titleWithBorders(label, theme)
          : FrameRenderer.plainTitle(label, theme);
      if (style.boldPrompt) stdout.writeln('${theme.bold}$top${theme.reset}');

      // Compute
      final ratio = current / total;
      final filled = (ratio * width).clamp(0, width).round();
      final percent = (ratio * 100).clamp(0, 100).round();

      // Build gradient fill with a moving shimmer head
      final buffer = StringBuffer();
      // Left border of the content area, matching ThemeDemo vibes
      buffer.write('${theme.gray}${style.borderVertical}${theme.reset} ');

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

      stdout.writeln(buffer.toString());

      // Second line with metrics: percent, elapsed, ETA
      final elapsed = stopwatch.elapsed;
      final estEta = _eta(elapsed, ratio, target);
      final metrics = StringBuffer();
      metrics.write('${theme.gray}${style.borderVertical}${theme.reset} ');
      metrics.write(
          '${theme.dim}Progress:${theme.reset} ${theme.accent}$percent%${theme.reset}   ');
      metrics.write(
          '${theme.dim}Elapsed:${theme.reset} ${_fmt(elapsed)}   ${theme.dim}ETA:${theme.reset} ${_fmt(estEta)}');
      stdout.writeln(metrics.toString());

      // Bottom border
      if (style.showBorder) {
        stdout.writeln(FrameRenderer.bottomLine(label, theme));
      }

      // Hints (non-interactive, just informational)
      stdout.writeln(Hints.bullets([
        'Animated progress bar',
        'Theme-aware accents',
      ], theme, dim: true));
    }

    // Entry animation: quick grow from 0 to a small head-start
    for (int i = 0; i <= math.min(6, width ~/ 6); i++) {
      render((total * (i / math.max(1, width))).round(), shimmerPhase: i);
      sleep(const Duration(milliseconds: 10));
    }

    // Main advance loop — ties steps to the target duration
    int current = 0;
    try {
      while (current < total) {
        final t = stopwatch.elapsed.inMilliseconds / target.inMilliseconds;
        final eased = _easeInOutCubic(t.clamp(0.0, 1.0));
        final next = (eased * total).clamp(0, total.toDouble()).round();
        if (next > current) current = next;

        final phase = (stopwatch.elapsedMilliseconds ~/ 50) % 1000;
        render(current, shimmerPhase: phase);

        // Small frame delay; high-ish FPS for smooth shimmer
        sleep(const Duration(milliseconds: 24));
      }
    } finally {
      cleanup();
    }

    // Completion flourish — a few shimmering frames
    for (int i = 0; i < 4; i++) {
      render(total, shimmerPhase: i * 2);
      sleep(const Duration(milliseconds: 30));
    }

    Terminal.clearAndHome();
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

double _easeInOutCubic(double t) {
  if (t < 0.5) {
    return 4 * t * t * t;
  } else {
    final f = ((2 * t) - 2);
    return 0.5 * f * f * f + 1;
  }
}


