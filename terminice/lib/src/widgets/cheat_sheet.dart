import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/prompt_runner.dart';
import '../system/table_renderer.dart';

/// CheatSheet – command list with shortcuts and usage.
///
/// Designed to align with ThemeDemo styling: framed title line,
/// subtle separators, accent headers, and tasteful dim text.
class CheatSheet {
  /// Title at the top of the sheet.
  final String title;

  /// Rows of [command, shortcut, usage].
  final List<List<String>> entries;

  /// Visual theme.
  final PromptTheme theme;

  CheatSheet(
    this.entries, {
    this.title = 'Cheat Sheet',
    this.theme = PromptTheme.dark,
  });

  /// Renders the cheat sheet once. Non-interactive.
  void show() {
    final out = RenderOutput();
    _render(out);
  }

  void _render(RenderOutput out) {
    // Header
    final frame = FramedLayout(title, theme: theme);
    out.writeln('${theme.bold}${frame.top()}${theme.reset}');

    // Create table renderer with Command (left), Shortcut (center), Usage (left)
    final renderer = TableRenderer.withAlignments(
      const ['Command', 'Shortcut', 'Usage'],
      const [ColumnAlign.left, ColumnAlign.center, ColumnAlign.left],
      theme: theme,
      zebraStripes: true,
    );

    // Compute widths from entries
    renderer.computeWidths(entries);

    // Render header and connector
    out.writeln(renderer.headerLine());
    out.writeln(renderer.connectorLine());

    // Render data rows
    for (var i = 0; i < entries.length; i++) {
      out.writeln(renderer.rowLine(entries[i], index: i));
    }

    // Bottom border to balance the header line
    out.writeln(frame.bottom());
  }

  /// Convenience: alias to [show].
  void run() => show();
}
