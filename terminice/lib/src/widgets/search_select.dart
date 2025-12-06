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
class SearchSelectPrompt {
  final List<String> allOptions;
  final String prompt;
  final bool multiSelect;
  final bool showSearch;
  final int maxVisible;
  final PromptTheme theme;

  SearchSelectPrompt(
    this.allOptions, {
    this.prompt = 'Select an option',
    this.multiSelect = false,
    this.showSearch = false,
    this.maxVisible = 10,
    this.theme = PromptTheme.dark,
  });

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
