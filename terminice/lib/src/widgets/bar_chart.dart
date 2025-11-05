import 'dart:io';

import '../style/theme.dart';
import '../system/frame_renderer.dart';

/// BarChartWidget – colored horizontal bar chart in the terminal.
///
/// Aligns with ThemeDemo styling:
/// - Themed title bar and optional bottom border
/// - Left gutter uses the theme's vertical border glyph
/// - Tasteful use of accent/highlight/selection/info/warn colors
class BarChartWidget {
  final List<BarChartItem> items;
  final PromptTheme theme;
  final String? title;
  final int barWidth;
  final bool showValues;
  final String Function(double value)? valueFormatter;
  final BarStyle style;

  BarChartWidget(
    this.items, {
    this.theme = const PromptTheme(),
    this.title,
    this.barWidth = 30,
    this.showValues = true,
    this.valueFormatter,
    this.style = BarStyle.solid,
  }) : assert(barWidth >= 6);

  void show() {
    final style = theme.style;
    final label = (title == null || title!.isEmpty) ? 'Bar Chart' : title!;

    final top = style.showBorder
        ? FrameRenderer.titleWithBorders(label, theme)
        : FrameRenderer.plainTitle(label, theme);
    stdout.writeln('${theme.bold}$top${theme.reset}');

    if (items.isEmpty) {
      _line('${theme.dim}(no data)${theme.reset}');
      if (style.showBorder) {
        stdout.writeln(FrameRenderer.bottomLine(label, theme));
      }
      return;
    }

    final nameW = _cap(_maxLen(items.map((e) => e.label.length)), 6, 24);
    final maxVal = items.map((e) => e.value).fold<double>(0, (a, b) => a > b ? a : b);

    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      final baseColor = it.color ?? _palette(i);
      final ratio = maxVal > 0 ? (it.value / maxVal).clamp(0, 1.0) : 0.0;
      final filled = (ratio * barWidth).round();

      final bar = _renderBar(baseColor, barWidth, filled, i);

      final labelStr = _pad(_truncate(it.label, nameW), nameW);
      final valueStr = showValues
          ? '  ${theme.selection}${_formatValue(it.value)}${theme.reset}'
          : '';

      _line('${theme.bold}${theme.accent}$labelStr${theme.reset}  $bar$valueStr');
    }

    if (style.showBorder) {
      stdout.writeln(FrameRenderer.bottomLine(label, theme));
    }
  }

  String _renderBar(String baseColor, int width, int filled, int barIndex) {
    switch (style) {
      case BarStyle.solid:
        return _barSolid(baseColor, width, filled);
      case BarStyle.thin:
        return _barThin(baseColor, width, filled);
      case BarStyle.striped:
        return _barStriped(baseColor, width, filled);
      case BarStyle.dotted:
        return _barDotted(baseColor, width, filled);
      case BarStyle.gradient:
        return _barGradient(baseColor, width, filled);
    }
  }

  String _barSolid(String color, int width, int filled) {
    final b = StringBuffer();
    for (int x = 0; x < width; x++) {
      final on = x < filled;
      b.write(on ? '$color█${theme.reset}' : '${theme.dim}░${theme.reset}');
    }
    return b.toString();
  }

  String _barThin(String color, int width, int filled) {
    final b = StringBuffer();
    for (int x = 0; x < width; x++) {
      final on = x < filled;
      b.write(on ? '$color─${theme.reset}' : '${theme.dim}─${theme.reset}');
    }
    return b.toString();
  }

  String _barStriped(String color, int width, int filled) {
    final b = StringBuffer();
    for (int x = 0; x < width; x++) {
      final on = x < filled;
      if (on) {
        final stripeColor = (x % 2 == 0) ? color : theme.highlight;
        b.write('$stripeColor█${theme.reset}');
      } else {
        b.write('${theme.dim}░${theme.reset}');
      }
    }
    return b.toString();
  }

  String _barDotted(String color, int width, int filled) {
    final b = StringBuffer();
    for (int x = 0; x < width; x++) {
      final on = x < filled;
      b.write(on ? '$color•${theme.reset}' : '${theme.dim}·${theme.reset}');
    }
    return b.toString();
  }

  String _barGradient(String color, int width, int filled) {
    const shades = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];
    final b = StringBuffer();
    for (int x = 0; x < width; x++) {
      if (x < filled) {
        final t = width <= 1 ? 1.0 : (x / (width - 1));
        final idx = (t * (shades.length - 1)).clamp(0, (shades.length - 1).toDouble()).round();
        b.write('$color${shades[idx]}${theme.reset}');
      } else {
        b.write('${theme.dim}▁${theme.reset}');
      }
    }
    return b.toString();
  }

  String _formatValue(double v) {
    if (valueFormatter != null) return valueFormatter!(v);
    // Default: compact when large, fixed(1) for fractional.
    if (v.abs() >= 1000) {
      if (v.abs() >= 1000000) {
        return '${(v / 1000000).toStringAsFixed(1)}M';
      }
      return '${(v / 1000).toStringAsFixed(1)}k';
    }
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  void _line(String content) {
    final s = theme.style;
    stdout.writeln('${theme.gray}${s.borderVertical}${theme.reset} $content');
  }

  String _palette(int index) {
    switch (index % 5) {
      case 0:
        return theme.accent;
      case 1:
        return theme.highlight;
      case 2:
        return theme.selection;
      case 3:
        return theme.info;
      default:
        return theme.warn;
    }
  }

  int _maxLen(Iterable<int> lengths) {
    var max = 0;
    for (final l in lengths) {
      if (l > max) max = l;
    }
    return max;
  }

  int _cap(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  String _pad(String text, int width) {
    if (text.length >= width) return text;
    return text + ' ' * (width - text.length);
  }

  String _truncate(String text, int width) {
    if (text.length <= width) return text;
    if (width <= 1) return text.substring(0, width);
    return text.substring(0, width - 1) + '…';
  }
}

/// Styles for rendering the bar fill.
enum BarStyle { solid, thin, striped, dotted, gradient }

class BarChartItem {
  final String label;
  final double value;
  final String? color; // Optional ANSI color to override palette

  const BarChartItem(this.label, this.value, {this.color});
}

/// Convenience function mirroring the requested API name.
void barChart(
  List<BarChartItem> items, {
  PromptTheme theme = const PromptTheme(),
  String? title,
  int barWidth = 30,
  bool showValues = true,
  String Function(double value)? valueFormatter,
}) {
  BarChartWidget(
    items,
    theme: theme,
    title: title,
    barWidth: barWidth,
    showValues: showValues,
    valueFormatter: valueFormatter,
  ).show();
}


