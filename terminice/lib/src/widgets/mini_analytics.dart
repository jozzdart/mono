import 'dart:io';

import '../style/theme.dart';
import '../system/frame_renderer.dart';

/// MiniAnalytics – compact trend with growth percent and arrow.
///
/// Aligns with ThemeDemo styling:
/// - Themed title bar and bottom border when enabled by theme.style.showBorder
/// - Left gutter uses the theme's vertical border glyph
/// - Uses selection/accent colors for emphasis, info/error for change tones
class MiniAnalytics {
  /// Time-ordered numeric series to render as a sparkline.
  final List<num> series;

  /// Short label shown before the sparkline.
  final String label;

  /// Theme controlling colors and border glyphs.
  final PromptTheme theme;

  /// Optional title for the frame header (defaults to 'Mini Analytics').
  final String? title;

  /// Target width for the sparkline (characters).
  final int sparklineWidth;

  MiniAnalytics({
    required this.series,
    this.label = 'Growth',
    this.theme = const PromptTheme(),
    this.title,
    this.sparklineWidth = 32,
  });

  void show() {
    final style = theme.style;
    final headerLabel = (title == null || title!.isEmpty) ? 'Mini Analytics' : title!;

    final top = style.showBorder
        ? FrameRenderer.titleWithBorders(headerLabel, theme)
        : FrameRenderer.plainTitle(headerLabel, theme);
    stdout.writeln('${theme.bold}$top${theme.reset}');

    final growth = _computeGrowthPercent(series);
    final growthText = _formatPercent(growth);
    final changeTone = growth > 0
        ? theme.info
        : (growth < 0 ? theme.error : theme.gray);
    final arrow = growth > 0
        ? '▲'
        : (growth < 0 ? '▼' : style.arrow);

    final spark = _buildSparkline(series, sparklineWidth);

    final line = StringBuffer();
    line.write('${theme.gray}${style.borderVertical}${theme.reset} ');
    line.write('${theme.dim}$label:${theme.reset} ');
    line.write('${theme.accent}$spark${theme.reset}  ');
    line.write('$changeTone$arrow${theme.reset} ');
    line.write('${theme.selection}${theme.bold}$growthText${theme.reset}');

    stdout.writeln(line.toString());

    if (style.showBorder) {
      stdout.writeln(FrameRenderer.bottomLine(headerLabel, theme));
    }
  }

  static double _computeGrowthPercent(List<num> data) {
    if (data.isEmpty) return 0;
    if (data.length == 1) return 0;
    final first = data.first.toDouble();
    final last = data.last.toDouble();
    if (first == 0) return 0;
    return ((last - first) / first) * 100.0;
  }

  static String _formatPercent(double p) {
    final sign = p > 0 ? '+' : '';
    // One decimal place, trim -0.0
    final v = p.abs() < 0.05 ? 0 : p;
    return '$sign${v.toStringAsFixed(1)}%';
  }

  static String _buildSparkline(List<num> data, int width) {
    if (data.isEmpty) return ''.padLeft(width, ' ');

    final values = data.map((e) => e.toDouble()).toList(growable: false);
    final sampled = _resample(values, width);

    final minV = sampled.reduce((a, b) => a < b ? a : b);
    final maxV = sampled.reduce((a, b) => a > b ? a : b);

    if (maxV - minV == 0) {
      // Flat line
      return List.filled(sampled.length, _levels[1]).join();
    }

    final buf = StringBuffer();
    for (final v in sampled) {
      final t = (v - minV) / (maxV - minV);
      final idx = (t * (_levels.length - 1)).clamp(0, (_levels.length - 1).toDouble()).round();
      buf.write(_levels[idx]);
    }
    return buf.toString();
  }

  static List<double> _resample(List<double> values, int width) {
    if (width <= 0) return const [];
    if (values.length == width) return values;

    if (values.length < width) {
      // Pad by linear interpolation between points
      final result = <double>[];
      for (int i = 0; i < values.length - 1; i++) {
        final a = values[i];
        final b = values[i + 1];
        result.add(a);
        // number of inserts for this gap proportional to remaining space
        final remainingGaps = values.length - 1;
        final totalToAdd = (width - values.length);
        final perGap = (totalToAdd / remainingGaps).ceil();
        for (int k = 1; k <= perGap && result.length < width - 1; k++) {
          final t = k / (perGap + 1);
          result.add(a + (b - a) * t);
        }
      }
      if (result.length < width) result.add(values.last);
      return result.take(width).toList(growable: false);
    }

    // Downsample by averaging into buckets
    final bucketSize = values.length / width;
    final out = List<double>.filled(width, 0);
    for (int i = 0; i < width; i++) {
      final start = (i * bucketSize).floor();
      final end = ((i + 1) * bucketSize).floor().clamp(start + 1, values.length);
      double sum = 0;
      int count = 0;
      for (int j = start; j < end; j++) {
        sum += values[j];
        count++;
      }
      out[i] = count == 0 ? values[start] : sum / count;
    }
    return out;
  }

  static const List<String> _levels = [
    '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'
  ];
}

/// Convenience wrapper mirroring other widgets.
void miniAnalytics(
  List<num> series, {
  String label = 'Growth',
  PromptTheme theme = const PromptTheme(),
  String? title,
  int sparklineWidth = 32,
}) {
  MiniAnalytics(
    series: series,
    label: label,
    theme: theme,
    title: title,
    sparklineWidth: sparklineWidth,
  ).show();
}


