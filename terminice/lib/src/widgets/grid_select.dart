import 'package:terminice/terminice.dart';

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
/// ```dart
/// // Fluent API
/// final selected = GridSelectPrompt(options)
///   .withFireTheme()
///   .run();
///
/// // With shared config
/// final selected = GridSelectPrompt(options).run();
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

  /// Creates a grid select prompt.
  ///
  /// Accepts either:
  /// - A direct [theme] parameter (for convenience)
  GridSelectPrompt(
    this.options, {
    this.prompt = 'Select',
    this.columns = 0,
    this.multiSelect = false,
    this.cellWidth,
    this.maxColumns,
    this.theme = PromptTheme.dark,
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
