import 'dart:math';

import '../style/theme.dart';
import '../system/hints.dart';
import '../system/framed_layout.dart';
import '../system/prompt_runner.dart';
import '../system/text_utils.dart' as text;

/// Colorful table rendering with alignment and borders, aligned with ThemeDemo styling.
///
/// - Title line uses FrameRenderer for consistent borders
/// - Header row in accent color and bold
/// - Column alignment: left, center, right
/// - Subtle zebra-striping for readability
/// - Uses Theme borderVertical as column separators
class TableView {
  final String title;
  final List<String> columns;
  final List<List<String>> rows;
  final List<TableAlign>? columnAlignments;
  final bool zebraStripes;
  final PromptTheme theme;

  TableView(
    this.title, {
    required this.columns,
    required this.rows,
    this.columnAlignments,
    this.zebraStripes = true,
    this.theme = PromptTheme.dark,
  }) : assert(columns.isNotEmpty, 'columns must not be empty');

  void run() {
    final out = RenderOutput();
    _render(out);
  }

  void _render(RenderOutput out) {
    final style = theme.style;

    // Title
    final frame = FramedLayout(title, theme: theme);
    final top = frame.top();
    out.writeln('${theme.bold}$top${theme.reset}');

    // Compute column widths based on visible (ANSI-stripped) content
    final widths =
        List<int>.generate(columns.length, (i) => text.visibleLength(columns[i]));
    for (final row in rows) {
      for (var i = 0; i < columns.length; i++) {
        final cell = (i < row.length) ? row[i] : '';
        widths[i] = max(widths[i], text.visibleLength(cell));
      }
    }

    // Rendering helpers
    String pad(String content, int width, TableAlign align) {
      switch (align) {
        case TableAlign.left:
          return text.padVisibleRight(content, width);
        case TableAlign.center:
          return text.padVisibleCenter(content, width);
        case TableAlign.right:
          return text.padVisibleLeft(content, width);
      }
    }

    TableAlign alignmentFor(int index) {
      final a = columnAlignments;
      if (a == null || a.isEmpty) return TableAlign.left;
      return a[min(index, a.length - 1)];
    }

    // Build header line
    final header = StringBuffer();
    header.write('${theme.gray}${style.borderVertical}${theme.reset} ');
    for (var i = 0; i < columns.length; i++) {
      if (i > 0) {
        header.write(' ${theme.gray}${style.borderVertical}${theme.reset} ');
      }
      header.write('${theme.bold}${theme.accent}');
      header.write(pad(columns[i], widths[i], alignmentFor(i)));
      header.write(theme.reset);
    }
    out.writeln(header.toString());

    // Connector under header sized to the table content width
    final tableWidth = 2 + // left border + space
        widths.fold<int>(0, (sum, w) => sum + w) +
        (columns.length - 1) * 3; // separators ' │ '
    out.writeln(
        '${theme.gray}${style.borderConnector}${'─' * tableWidth}${theme.reset}');

    // Rows
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      final rowBuf = StringBuffer();
      rowBuf.write('${theme.gray}${style.borderVertical}${theme.reset} ');

      final stripe = zebraStripes && (r % 2 == 1);
      final prefix = stripe ? theme.dim : '';
      final suffix = stripe ? theme.reset : '';

      for (var i = 0; i < columns.length; i++) {
        if (i > 0) {
          rowBuf.write(' ${theme.gray}${style.borderVertical}${theme.reset} ');
        }
        final cell = (i < row.length) ? row[i] : '';
        rowBuf.write(prefix);
        rowBuf.write(pad(cell, widths[i], alignmentFor(i)));
        rowBuf.write(suffix);
      }
      out.writeln(rowBuf.toString());
    }

    // Bottom border line to balance the title
    if (style.showBorder) {
      out.writeln(frame.bottom());
    }

    // Hints
    out.writeln(Hints.bullets([
      'Arrow-friendly styling',
      'Accent header',
      'Zebra rows',
    ], theme, dim: true));
  }
}

enum TableAlign { left, center, right }

// Uses text.visibleLength and text.stripAnsi from text_utils.dart
