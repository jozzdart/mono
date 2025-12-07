import '../style/prompt_config.dart';
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
/// **Configuration:** Supports both direct theme and [PromptConfig]:
/// ```dart
/// // Fluent API
/// final selected = GridSelectPrompt(options)
///   .withFireTheme()
///   .run();
///
/// // With shared config
/// final config = PromptConfig.fire;
/// final selected = GridSelectPrompt(options, config: config).run();
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
  /// - A [PromptConfig] object (theme extracted automatically)
  /// - A direct [theme] parameter (for convenience)
  GridSelectPrompt(
    this.options, {
    this.prompt = 'Select',
    this.columns = 0,
    this.multiSelect = false,
    this.cellWidth,
    this.maxColumns,
    // Config object (preferred for shared configuration)
    PromptConfig? config,
    // Direct theme (for convenience)
    PromptTheme theme = PromptTheme.dark,
  }) : theme = config?.theme ?? theme;

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
