import 'package:terminice/terminice.dart';

/// Colorful table rendering with alignment and borders, aligned with ThemeDemo styling.
///
/// - Title line uses FrameRenderer for consistent borders
/// - Header row in accent color and bold
/// - Column alignment: left, center, right
/// - Subtle zebra-striping for readability
/// - Uses Theme borderVertical as column separators
///
/// ```dart
/// TableView('Data', columns: cols, rows: data).withMatrixTheme().show();
/// ```
class TableView with Themeable {
  final String title;
  final List<String> columns;
  final List<List<String>> rows;
  final List<TableAlign>? columnAlignments;
  final bool zebraStripes;
  @override
  final PromptTheme theme;

  /// Creates a table view.
  ///
  /// Accepts either:
  /// - A direct [theme] parameter (for convenience)
  TableView(
    this.title, {
    required this.columns,
    required this.rows,
    this.columnAlignments,
    this.zebraStripes = true,
    this.theme = PromptTheme.dark,
  }) : assert(columns.isNotEmpty, 'columns must not be empty');

  @override
  TableView copyWithTheme(PromptTheme theme) {
    return TableView(
      title,
      columns: columns,
      rows: rows,
      columnAlignments: columnAlignments,
      zebraStripes: zebraStripes,
      theme: theme,
    );
  }

  /// Shows the table using centralized output.
  void show() {
    final out = RenderOutput();
    _render(out);
  }

  void _render(RenderOutput out) {
    final widgetFrame = FrameView(title: title, theme: theme);
    widgetFrame.showTo(out, (ctx) {
      // Create table renderer with alignments
      final alignments = _convertAlignments();
      final renderer = TableRenderer.withAlignments(
        columns,
        alignments,
        theme: theme,
        zebraStripes: zebraStripes,
      );

      // Compute widths and render
      renderer.computeWidths(rows);
      ctx.line(renderer.headerLine());
      ctx.line(renderer.connectorLine());
      for (var i = 0; i < rows.length; i++) {
        ctx.line(renderer.rowLine(rows[i], index: i));
      }
    });

    // Hints
    out.writeln(Hints.bullets([
      'Arrow-friendly styling',
      'Accent header',
      'Zebra rows',
    ], theme, dim: true));
  }

  List<ColumnAlign> _convertAlignments() {
    if (columnAlignments == null) return [];
    return columnAlignments!.map((a) {
      switch (a) {
        case TableAlign.left:
          return ColumnAlign.left;
        case TableAlign.center:
          return ColumnAlign.center;
        case TableAlign.right:
          return ColumnAlign.right;
      }
    }).toList();
  }
}

enum TableAlign { left, center, right }
