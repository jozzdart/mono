import '../style/theme.dart';
import '../system/highlighter.dart';
import '../system/key_bindings.dart';
import '../system/list_navigation.dart';
import '../system/prompt_runner.dart';
import '../system/text_input_buffer.dart';
import '../system/widget_frame.dart';

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
    return _searchSelect(
      allOptions,
      prompt: prompt,
      multiSelect: multiSelect,
      showSearch: showSearch,
      maxVisible: maxVisible,
      theme: theme,
    );
  }
}

/// ───────────────────────────── CORE ─────────────────────────────
List<String> _searchSelect(
  List<String> allOptions, {
  String prompt = 'Select an option',
  bool multiSelect = false,
  bool showSearch = false,
  int maxVisible = 10,
  PromptTheme theme = PromptTheme.dark,
}) {
  // Use centralized text input for search query handling
  final queryInput = TextInputBuffer();
  bool searchEnabled = showSearch;
  List<String> filtered = List.from(allOptions);
  final selectedSet = <String>{};
  bool cancelled = false;

  // Use centralized list navigation for selection & scrolling
  final nav = ListNavigation(
    itemCount: filtered.length,
    maxVisible: maxVisible,
  );

  void updateFilter() {
    if (!searchEnabled || queryInput.isEmpty) {
      filtered = List.from(allOptions);
    } else {
      final query = queryInput.text.toLowerCase();
      filtered =
          allOptions.where((o) => o.toLowerCase().contains(query)).toList();
    }
    nav.itemCount = filtered.length;
    nav.reset();
  }

  // Use KeyBindings for declarative key handling
  final bindings = KeyBindings.searchableList(
    onUp: () => nav.moveUp(),
    onDown: () => nav.moveDown(),
    onSearchToggle: () {
      searchEnabled = !searchEnabled;
      if (!searchEnabled) queryInput.clear();
      updateFilter();
    },
    searchBuffer: queryInput,
    isSearchEnabled: () => searchEnabled,
    onSearchInput: updateFilter,
    onToggle: multiSelect && filtered.isNotEmpty
        ? () {
            final current = filtered[nav.selectedIndex];
            if (selectedSet.contains(current)) {
              selectedSet.remove(current);
            } else {
              selectedSet.add(current);
            }
          }
        : null,
    hasMultiSelect: multiSelect,
    onCancel: () => cancelled = true,
  );

  // Use WidgetFrame for consistent frame rendering
  final frame = WidgetFrame(
    title: prompt,
    theme: theme,
    bindings: bindings,
    showConnector: true,
  );

  void render(RenderOutput out) {
    frame.render(out, (ctx) {
      // Search line
      ctx.searchLine(queryInput.text, enabled: searchEnabled);

      // Connector after search
      ctx.writeConnector();

      // Use ListNavigation's viewport for visible window
      final window = nav.visibleWindow(filtered);

      ctx.listWindow(
        window,
        selectedIndex: nav.selectedIndex,
        renderItem: (item, index, isFocused) {
          final isChecked = selectedSet.contains(item);
          // Use LineBuilder for arrow and checkbox
          final checkbox = multiSelect ? ctx.lb.checkbox(isChecked) : ' ';
          final prefix = ctx.lb.arrow(isFocused);
          final lineText =
              '$prefix $checkbox ${highlightSubstring(item, queryInput.text, theme, enabled: searchEnabled)}';
          // Use LineBuilder's writeLine for consistent highlight handling
          ctx.highlightedLine(lineText, highlighted: isFocused);
        },
      );

      if (filtered.isEmpty) {
        ctx.emptyMessage('no matches');
      }
    });
  }

  updateFilter();

  final runner = PromptRunner(hideCursor: true);
  final result = runner.runWithBindings(
    render: render,
    bindings: bindings,
  );

  if (cancelled || result == PromptResult.cancelled || filtered.isEmpty) {
    return [];
  }

  if (multiSelect) {
    if (selectedSet.isEmpty) selectedSet.add(filtered[nav.selectedIndex]);
    return selectedSet.toList();
  } else {
    return [filtered[nav.selectedIndex]];
  }
}
