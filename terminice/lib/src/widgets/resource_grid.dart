import 'dart:math' as math;

import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/line_builder.dart';
import '../system/prompt_runner.dart';
import '../system/terminal.dart';
import '../system/text_utils.dart' as text;

/// ResourceGrid – tabular boxes with CPU/Memory/IO graphs.
///
/// Aligns with ThemeDemo styling:
/// - Themed title bar and bottom border
/// - Left gutter uses the theme's vertical border glyph
/// - Column separators use the theme's vertical border glyph
/// - Accent/info/warn colors for different metrics
class ResourceGrid {
  final String title;
  final List<ResourceCell> resources;
  final PromptTheme theme;

  /// Fixed number of columns; if <= 0, columns are computed from terminal width.
  final int columns;

  /// Width of each cell content (not counting separators). Must be >= 20.
  final int cellWidth;

  /// Target width of sparklines inside cells.
  final int sparklineWidth;

  ResourceGrid({
    required this.title,
    required this.resources,
    this.theme = const PromptTheme(),
    this.columns = 0,
    this.cellWidth = 30,
    this.sparklineWidth = 18,
  }) : assert(cellWidth >= 20, 'cellWidth must be at least 20');

  void show() {
    final out = RenderOutput();
    _render(out);
  }

  void _render(RenderOutput out) {
    // Use centralized line builder for consistent styling
    final lb = LineBuilder(theme);
    final style = theme.style;

    // Title
    final frame = FramedLayout(title, theme: theme);
    out.writeln('${theme.bold}${frame.top()}${theme.reset}');

    if (resources.isEmpty) {
      out.writeln(lb.emptyLine('no resources'));
      if (style.showBorder) {
        out.writeln(frame.bottom());
      }
      return;
    }

    // Layout
    final int cols = _computeColumns();
    final int rows = (resources.length + cols - 1) ~/ cols;
    final String colSep = ' ${theme.gray}${style.borderVertical}${theme.reset} ';

    // Render row-by-row; each cell expands to the same number of lines
    for (int r = 0; r < rows; r++) {
      final start = r * cols;
      final end = math.min(start + cols, resources.length);
      final slice = resources.sublist(start, end);

      final List<List<String>> renderedCells = slice
          .map((cell) => _renderCell(cell, width: cellWidth, spark: sparklineWidth))
          .toList(growable: false);

      // Normalize height across cells in this row
      final int linesPerCell = renderedCells
          .map((c) => c.length)
          .fold<int>(0, (a, b) => math.max(a, b));
      for (final c in renderedCells) {
        while (c.length < linesPerCell) {
          c.add(' ' * cellWidth);
        }
      }

      // Print each visual line across the row
      for (int line = 0; line < linesPerCell; line++) {
        final buf = StringBuffer();
        buf.write(lb.gutter());
        for (int i = 0; i < renderedCells.length; i++) {
          if (i > 0) buf.write(colSep);
          buf.write(renderedCells[i][line]);
        }
        out.writeln(buf.toString());
      }

      // After each row of cells, print a subtle connector
      if (r < rows - 1) {
        final connector = StringBuffer();
        connector.write('${theme.gray}${style.borderConnector}${theme.reset}');
        connector.write('${theme.gray}${'─' * _rowContentWidth(renderedCells.length)}${theme.reset}');
        out.writeln(connector.toString());
      }
    }

    // Bottom border line to balance the title
    if (style.showBorder) {
      out.writeln(frame.bottom());
    }
  }

  int _computeColumns() {
    if (columns > 0) return columns;
    final termWidth = TerminalInfo.columns;
    // Left gutter is "│ " (2 chars). Separator between cells is " │ " (3 chars).
    const leftPrefix = 2;
    const sepWidth = 3;
    final unit = cellWidth + sepWidth;
    final colsByWidth = math.max(1, ((termWidth - leftPrefix) + sepWidth) ~/ unit);
    // Aim for a balanced grid roughly sqrt(n)
    final desired = math.max(2, math.min(resources.length, math.sqrt(resources.length).ceil()));
    return math.min(colsByWidth, desired);
  }

  int _rowContentWidth(int cellsInRow) {
    // width = left space (1 after gutter) + cells * cellWidth + (cells-1) * 3 (separators)
    if (cellsInRow <= 0) return 0;
    return 1 + (cellsInRow * cellWidth) + (math.max(0, cellsInRow - 1) * 3);
  }

  List<String> _renderCell(ResourceCell cell, {required int width, required int spark}) {
    // Name line, clipped/padded to width
    final name = _clipPad(' ${theme.bold}${theme.accent}${cell.name}${theme.reset}', width);

    // Metric lines
    final cpuPct = (cell.cpuHistory.isEmpty ? 0 : (cell.cpuHistory.last * 100)).clamp(0, 100).round();
    final memPct = (cell.memHistory.isEmpty ? 0 : (cell.memHistory.last * 100)).clamp(0, 100).round();
    final ioPct = (cell.ioHistory.isEmpty ? 0 : (cell.ioHistory.last * 100)).clamp(0, 100).round();

    final cpu = _metricLine('CPU', cell.cpuHistory, spark,
        color: theme.info, pct: cpuPct, width: width);
    final mem = _metricLine('MEM', cell.memHistory, spark,
        color: theme.warn, pct: memPct, width: width);
    final io = _metricLine('IO', cell.ioHistory, spark,
        color: theme.accent, pct: ioPct, width: width);

    return [name, cpu, mem, io];
  }

  String _metricLine(String label, List<double> history, int sparkWidth,
      {required String color, required int pct, required int width}) {
    final spark = _sparkline(history, width: sparkWidth, color: color);
    final pctStr = '${theme.dim}${pct.toString().padLeft(3)}%${theme.reset}';
    final text = ' ${theme.dim}$label:${theme.reset} $spark  $pctStr';
    return _clipPad(text, width);
  }

  String _clipPad(String styledText, int width) {
    final visible = text.visibleLength(styledText);
    if (visible == width) return styledText;
    if (visible < width) {
      return styledText + (' ' * (width - visible));
    }
    // Clip while preserving ANSI codes – we trim raw, but add ellipsis.
    // We approximate by clipping the visible content, which is sufficient
    // for our short strings here.
    final plain = text.stripAnsi(styledText);
    final clipped = '${plain.substring(0, math.max(0, width - 1))}…';
    return clipped;
  }

  String _sparkline(List<double> values, {int width = 18, String? color}) {
    if (values.isEmpty) {
      return '${theme.dim}${'·' * width}${theme.reset}';
    }
    final samples = _resample(values, width);
    const chars = ['▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'];
    final buf = StringBuffer();
    final c = color ?? theme.accent;
    for (final v in samples) {
      final clamped = v.clamp(0.0, 1.0);
      final idx = (clamped * (chars.length - 1)).round();
      buf.write('$c${chars[idx]}${theme.reset}');
    }
    return buf.toString();
  }

  List<double> _resample(List<double> data, int target) {
    if (target <= 0) return const [];
    if (data.length == target) return data;
    if (data.length > target) {
      // Downsample by picking evenly spaced points
      final out = <double>[];
      for (int i = 0; i < target; i++) {
        final pos = i * (data.length - 1) / (target - 1);
        final idx = pos.floor();
        final frac = pos - idx;
        if (idx + 1 < data.length) {
          final a = data[idx];
          final b = data[idx + 1];
          out.add(a + (b - a) * frac);
        } else {
          out.add(data.last);
        }
      }
      return out;
    }
    // Upsample by linear interpolation
    final out = <double>[];
    for (int i = 0; i < target; i++) {
      final pos = i * (data.length - 1) / (target - 1);
      final idx = pos.floor();
      final frac = pos - idx;
      if (idx + 1 < data.length) {
        final a = data[idx];
        final b = data[idx + 1];
        out.add(a + (b - a) * frac);
      } else {
        out.add(data.last);
      }
    }
    return out;
  }
}

class ResourceCell {
  final String name;
  final List<double> cpuHistory; // values in [0..1]
  final List<double> memHistory; // values in [0..1]
  final List<double> ioHistory; // values in [0..1]

  ResourceCell({
    required this.name,
    required this.cpuHistory,
    required this.memHistory,
    required this.ioHistory,
  });
}

// Uses text.stripAnsi and text.visibleLength from text_utils.dart


