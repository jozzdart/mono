import '../style/theme.dart';
import '../system/hints.dart';
import '../system/selectable_grid_prompt.dart';
import '../system/terminal.dart';

/// TagSelector – choose multiple "chips" (tags) from a list.
///
/// Controls:
/// - Arrow keys navigate between chips
/// - Space toggles selection
/// - Enter confirms
/// - Esc / Ctrl+C cancels (returns empty list)
///
/// **Implementation:** Uses [SelectableGridPrompt] for core functionality,
/// demonstrating composition over inheritance.
class TagSelector {
  final List<String> tags;
  final String prompt;
  final PromptTheme theme;
  final int? maxContentWidth;
  final int minContentWidth;
  final int minColumnWidth;
  final int maxColumnWidth;
  final bool useTerminalWidth;

  TagSelector(
    this.tags, {
    this.prompt = 'Select tags',
    this.theme = PromptTheme.dark,
    this.maxContentWidth,
    this.minContentWidth = 32,
    this.minColumnWidth = 8,
    this.maxColumnWidth = 24,
    this.useTerminalWidth = true,
  });

  List<String> run() {
    if (tags.isEmpty) return [];

    // Compute layout for chip-style grid
    ({int contentWidth, int colWidth, int cols}) computeLayout() {
      const framePrefix = 2;
      final termCols = useTerminalWidth ? TerminalInfo.columns : 80;
      final targetContent = (maxContentWidth != null)
          ? maxContentWidth!.clamp(minContentWidth, termCols - 4)
          : (termCols - 4).clamp(minContentWidth, termCols);

      final longest = tags.fold<int>(0, (m, t) => t.length > m ? t.length : m);
      final naturalChip = longest + 4; // [ tag ]
      final colWidth = naturalChip.clamp(minColumnWidth, maxColumnWidth);

      final available = targetContent - framePrefix;
      final cols =
          available <= 0 ? 1 : (available + 1) ~/ (colWidth + 1).clamp(1, 99);

      return (contentWidth: targetContent, colWidth: colWidth, cols: cols);
    }

    final initialLayout = computeLayout();

    // Use SelectableGridPrompt with custom chip rendering
    final gridPrompt = SelectableGridPrompt<String>(
      title: prompt,
      items: tags,
      theme: theme,
      multiSelect: true,
      columns: initialLayout.cols,
      cellWidth: initialLayout.colWidth,
    );

    // Run with custom rendering for chip style
    return gridPrompt.runCustom(
      renderContent: (ctx) {
        final l = computeLayout();
        // Update columns in case terminal resized
        gridPrompt.grid.columns = l.cols;

        // Summary line
        final count = gridPrompt.selection.count;
        final summary = count == 0
            ? ctx.lb.emptyMessage('none selected')
            : '${theme.accent}$count selected${theme.reset}';
        ctx.gutterLine('${Hints.comma([
              'Space to toggle',
              'Enter to confirm',
              'Esc to cancel'
            ], theme)}  $summary');

        ctx.writeConnector();

        final rows = (tags.length / l.cols).ceil().clamp(1, 999);
        for (var r = 0; r < rows; r++) {
          final pieces = <String>[];
          for (var c = 0; c < l.cols; c++) {
            final idx = r * l.cols + c;
            if (idx >= tags.length) break;
            pieces.add(_renderChip(
              tags[idx],
              gridPrompt.grid.isFocused(idx),
              gridPrompt.selection.isSelected(idx),
              l.colWidth,
            ));
          }
          ctx.gutterLine(pieces.join(' '));
        }
      },
    );
  }

  String _renderChip(
      String tag, bool isFocused, bool isSelected, int colWidth) {
    final raw = '[ $tag ]';
    final padding = (colWidth - raw.length).clamp(0, 1000);
    final padded = raw + ' ' * padding;

    if (isFocused) {
      return '${theme.inverse}${theme.selection}$padded${theme.reset}';
    }
    if (isSelected) {
      return padded.replaceFirst(tag, '${theme.accent}$tag${theme.reset}');
    }
    return '${theme.dim}$padded${theme.reset}';
  }
}
