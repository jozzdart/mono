import 'dart:math';
import 'dart:io';

import '../style/theme.dart';
import '../system/terminal.dart';
import '../system/hints.dart';
import '../system/frame_renderer.dart';

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
    Terminal.clearAndHome();

    final style = theme.style;

    // Title
    final top = style.showBorder
        ? FrameRenderer.titleWithBorders(title, theme)
        : FrameRenderer.plainTitle(title, theme);
    stdout.writeln('${theme.bold}$top${theme.reset}');

    // Compute column widths based on visible (ANSI-stripped) content
    final widths = List<int>.generate(columns.length, (i) => _visible(columns[i]).length);
    for (final row in rows) {
      for (var i = 0; i < columns.length; i++) {
        final cell = (i < row.length) ? row[i] : '';
        widths[i] = max(widths[i], _visible(cell).length);
      }
    }

    // Rendering helpers
    String pad(String text, int width, TableAlign align) {
      final visible = _visible(text);
      final padCount = max(0, width - visible.length);
      switch (align) {
        case TableAlign.left:
          return text + ' ' * padCount;
        case TableAlign.center:
          final left = padCount ~/ 2;
          final right = padCount - left;
          return (' ' * left) + text + (' ' * right);
        case TableAlign.right:
          return (' ' * padCount) + text;
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
      if (i > 0) header.write(' ${theme.gray}${style.borderVertical}${theme.reset} ');
      header.write('${theme.bold}${theme.accent}');
      header.write(pad(columns[i], widths[i], alignmentFor(i)));
      header.write(theme.reset);
    }
    stdout.writeln(header.toString());

    // Connector under header sized to the table content width
    final tableWidth = 2 + // left border + space
        widths.fold<int>(0, (sum, w) => sum + w) +
        (columns.length - 1) * 3; // separators ' │ '
    stdout.writeln(
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
        if (i > 0) rowBuf.write(' ${theme.gray}${style.borderVertical}${theme.reset} ');
        final cell = (i < row.length) ? row[i] : '';
        rowBuf.write(prefix);
        rowBuf.write(pad(cell, widths[i], alignmentFor(i)));
        rowBuf.write(suffix);
      }
      stdout.writeln(rowBuf.toString());
    }

    // Bottom border line to balance the title
    if (style.showBorder) {
      stdout.writeln(FrameRenderer.bottomLine(title, theme));
    }

    // Hints
    stdout.writeln(Hints.bullets([
      'Arrow-friendly styling',
      'Accent header',
      'Zebra rows',
    ], theme, dim: true));
  }
}

enum TableAlign { left, center, right }

String _visible(String s) {
  // Remove ANSI escape sequences like \x1B[...m
  return s.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');
}


