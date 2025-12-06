import '../style/theme.dart';
import '../system/selectable_grid_prompt.dart';

/// GridSelectPrompt – 2D grid selection with arrow-key navigation.
///
/// Controls:
/// - Arrow keys move across cells (wraps around edges)
/// - Space toggles selection in multi-select mode
/// - Enter confirms
/// - Esc cancels
///
/// **Implementation:** Uses [SelectableGridPrompt] for core functionality,
/// demonstrating composition over inheritance.
///
/// **Mixins:** Implements [Themeable] for fluent theme configuration:
/// ```dart
/// final selected = GridSelectPrompt(options)
///   .withFireTheme()
///   .run();
/// ```
class GridSelectPrompt with Themeable {
  final List<String> options;
  final String prompt;
  final int columns; // If <= 0, auto-calc based on terminal width
  final bool multiSelect;
  @override
  final PromptTheme theme;
  final int? cellWidth; // Optional fixed width; auto-calculated if null
  final int? maxColumns; // Optional cap for auto columns

  GridSelectPrompt(
    this.options, {
    this.prompt = 'Select',
    this.columns = 0,
    this.multiSelect = false,
    this.theme = PromptTheme.dark,
    this.cellWidth,
    this.maxColumns,
  });

  @override
  GridSelectPrompt copyWithTheme(PromptTheme theme) {
    return GridSelectPrompt(
      options,
      prompt: prompt,
      columns: columns,
      multiSelect: multiSelect,
      theme: theme,
      cellWidth: cellWidth,
      maxColumns: maxColumns,
    );
  }

  List<String> run() {
    if (options.isEmpty) return [];

    // Use SelectableGridPrompt for all functionality
    return SelectableGridPrompt<String>(
      title: prompt,
      items: options,
      theme: theme,
      multiSelect: multiSelect,
      columns: columns,
      cellWidth: cellWidth,
      maxColumns: maxColumns,
    ).run();
  }
}
