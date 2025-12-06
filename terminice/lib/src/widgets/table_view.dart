import '../style/theme.dart';
import '../system/hints.dart';
import '../system/framed_layout.dart';
import '../system/prompt_runner.dart';
import '../system/table_renderer.dart';

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
    out.writeln(renderer.headerLine());
    out.writeln(renderer.connectorLine());
    for (var i = 0; i < rows.length; i++) {
      out.writeln(renderer.rowLine(rows[i], index: i));
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
