import '../style/theme.dart';
import '../system/table_renderer.dart';
import '../system/widget_frame.dart';

/// CheatSheet – command list with shortcuts and usage.
///
/// Designed to align with ThemeDemo styling: framed title line,
/// subtle separators, accent headers, and tasteful dim text.
///
/// **Mixins:** Implements [Themeable] for fluent theme configuration:
/// ```dart
/// CheatSheet(entries).withMatrixTheme().show();
/// ```
class CheatSheet with Themeable {
  /// Title at the top of the sheet.
  final String title;

  /// Rows of [command, shortcut, usage].
  final List<List<String>> entries;

  /// Visual theme.
  @override
  final PromptTheme theme;

  CheatSheet(
    this.entries, {
    this.title = 'Cheat Sheet',
    this.theme = PromptTheme.dark,
  });

  @override
  CheatSheet copyWithTheme(PromptTheme theme) {
    return CheatSheet(
      entries,
      title: title,
      theme: theme,
    );
  }

  /// Renders the cheat sheet once. Non-interactive.
  void show() {
    final frame = WidgetFrame(title: title, theme: theme);
    frame.show((ctx) {
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
      ctx.line(renderer.headerLine());
      ctx.line(renderer.connectorLine());

      // Render data rows
      for (var i = 0; i < entries.length; i++) {
        ctx.line(renderer.rowLine(entries[i], index: i));
      }
    });
  }

  /// Convenience: alias to [show].
  void run() => show();
}
