import '../style/prompt_config.dart';
import '../style/theme.dart';
import '../system/searchable_list_prompt.dart';

/// SearchSelectPrompt – filterable list with optional multi-select.
///
/// Controls:
/// - ↑ / ↓ navigate
/// - / toggle search
/// - Type to filter (when search enabled)
/// - Space toggle selection (multi-select)
/// - Enter confirm
/// - Esc / Ctrl+C cancel
///
/// **Implementation:** Uses [SearchableListPrompt] for core functionality,
/// demonstrating composition over inheritance.
///
/// **Configuration:** Supports both direct theme and [PromptConfig]:
/// ```dart
/// // Fluent API
/// final selected = SearchSelectPrompt(options)
///   .withMatrixTheme()
///   .run();
///
/// // With shared config
/// final config = PromptConfig.matrix;
/// final selected = SearchSelectPrompt(options, config: config).run();
/// ```
class SearchSelectPrompt with Themeable {
  final List<String> allOptions;
  final String prompt;
  final bool multiSelect;
  final bool showSearch;
  final int maxVisible;
  @override
  final PromptTheme theme;

  /// Creates a searchable select prompt.
  ///
  /// Accepts either:
  /// - A [PromptConfig] object (theme extracted automatically)
  /// - A direct [theme] parameter (for convenience)
  SearchSelectPrompt(
    this.allOptions, {
    this.prompt = 'Select an option',
    this.multiSelect = false,
    this.showSearch = false,
    this.maxVisible = 10,
    // Config object (preferred for shared configuration)
    PromptConfig? config,
    // Direct theme (for convenience)
    PromptTheme theme = PromptTheme.dark,
  }) : theme = config?.theme ?? theme;

  @override
  SearchSelectPrompt copyWithTheme(PromptTheme theme) {
    return SearchSelectPrompt(
      allOptions,
      prompt: prompt,
      multiSelect: multiSelect,
      showSearch: showSearch,
      maxVisible: maxVisible,
      theme: theme,
    );
  }

  List<String> run() {
    if (allOptions.isEmpty) return [];

    // Use SearchableListPrompt for all functionality
    return SearchableListPrompt<String>(
      title: prompt,
      items: allOptions,
      theme: theme,
      multiSelect: multiSelect,
      maxVisible: maxVisible,
      searchEnabled: showSearch,
    ).run();
  }
}
