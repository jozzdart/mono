import '../style/theme.dart';
import '../system/key_events.dart';
import '../system/highlighter.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/line_builder.dart';
import '../system/list_navigation.dart';
import '../system/prompt_runner.dart';
import '../system/text_input_buffer.dart';

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
  final style = theme.style;
  // Use centralized line builder for consistent styling
  final lb = LineBuilder(theme);

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

  void render(RenderOutput out) {
    final frame = FramedLayout(prompt, theme: theme);
    final topBorder = frame.top();
    if (style.boldPrompt) {
      out.writeln('${theme.bold}$topBorder${theme.reset}');
    } else {
      out.writeln(topBorder);
    }

    // Search line - using LineBuilder's gutter
    if (searchEnabled) {
      out.writeln(
          '${lb.gutter()}${theme.accent}Search:${theme.reset} ${queryInput.text}');
    } else {
      out.writeln(
          '${lb.gutter()}${theme.dim}(Search disabled — press / to enable)${theme.reset}');
    }

    if (style.showBorder) {
      out.writeln(frame.connector());
    }

    // Use ListNavigation's viewport for visible window
    final window = nav.visibleWindow(filtered);

    for (var i = 0; i < window.items.length; i++) {
      final absoluteIdx = window.start + i;
      final isHighlighted = nav.isSelected(absoluteIdx);
      final isChecked = selectedSet.contains(window.items[i]);
      // Use LineBuilder for arrow and checkbox
      final checkbox = multiSelect ? lb.checkbox(isChecked) : ' ';
      final prefix = lb.arrow(isHighlighted);
      final lineText =
          '$prefix $checkbox ${highlightSubstring(window.items[i], queryInput.text, theme, enabled: searchEnabled)}';
      // Use LineBuilder's writeLine for consistent highlight handling
      lb.writeLine(out, lineText, highlighted: isHighlighted);
    }

    if (filtered.isEmpty) {
      out.writeln(lb.emptyLine('no matches'));
    }

    if (style.showBorder) {
      out.writeln(frame.bottom());
    }

    final hints = <String>[Hints.hint('↑/↓', 'navigate', theme)];
    if (multiSelect) hints.add(Hints.hint('Space', 'select', theme));
    hints.addAll([
      Hints.hint('Enter', 'confirm', theme),
      Hints.hint('/', 'search', theme),
      Hints.hint('Esc', 'cancel', theme),
    ]);
    out.writeln(Hints.bullets(hints, theme));
  }

  updateFilter();

  final runner = PromptRunner(hideCursor: true);
  final result = runner.run(
    render: render,
    onKey: (ev) {
      if (ev.type == KeyEventType.enter) return PromptResult.confirmed;
      if (ev.type == KeyEventType.ctrlC) {
        cancelled = true;
        return PromptResult.cancelled;
      }

      // Space
      if (multiSelect && ev.type == KeyEventType.space && filtered.isNotEmpty) {
        final current = filtered[nav.selectedIndex];
        if (selectedSet.contains(current)) {
          selectedSet.remove(current);
        } else {
          selectedSet.add(current);
        }
      }

      // Toggle search
      else if (ev.type == KeyEventType.slash) {
        searchEnabled = !searchEnabled;
        if (!searchEnabled) queryInput.clear();
        updateFilter();
      }

      // Arrows / ESC
      else if (ev.type == KeyEventType.arrowUp) {
        nav.moveUp();
      } else if (ev.type == KeyEventType.arrowDown) {
        nav.moveDown();
      } else if (ev.type == KeyEventType.esc) {
        cancelled = true;
        return PromptResult.cancelled;
      }

      // Text input (typing, backspace) - handled by centralized TextInputBuffer
      else if (searchEnabled && queryInput.handleKey(ev)) {
        updateFilter();
      }

      return null;
    },
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
