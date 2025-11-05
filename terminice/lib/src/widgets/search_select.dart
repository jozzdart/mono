import 'dart:io';
import 'dart:math';

import '../style/theme.dart';
import '../system/terminal.dart';
import '../system/key_events.dart';
import '../system/highlighter.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';

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

  String query = '';
  bool searchEnabled = showSearch;
  List<String> filtered = List.from(allOptions);
  int selectedIndex = 0;
  final selectedSet = <String>{};
  int scrollOffset = 0;
  bool cancelled = false;

  // Setup terminal
  final term = Terminal.enterRaw();

  void cleanup() {
    term.restore();
    stdout.write('\x1B[?25h');
  }

  void updateFilter() {
    if (!searchEnabled || query.isEmpty) {
      filtered = List.from(allOptions);
    } else {
      filtered = allOptions
          .where((o) => o.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    selectedIndex = 0;
    scrollOffset = 0;
  }

  // highlighting handled by shared utility

  void render() {
    Terminal.clearAndHome();

    final frame = FramedLayout(prompt, theme: theme);
    final topBorder = frame.top();
    if (style.boldPrompt) {
      stdout.writeln('${theme.bold}$topBorder${theme.reset}');
    } else {
      stdout.writeln(topBorder);
    }

    if (searchEnabled) {
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} ${theme.accent}Search:${theme.reset} $query');
    } else {
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} ${theme.dim}(Search disabled — press / to enable)${theme.reset}');
    }

    if (style.showBorder) {
      stdout.writeln(frame.connector());
    }

    final end = min(scrollOffset + maxVisible, filtered.length);
    final start = scrollOffset;
    final visible = filtered.sublist(start, end);

    for (var i = 0; i < visible.length; i++) {
      final idx = start + i;
      final isHighlighted = idx == selectedIndex;
      final isChecked = selectedSet.contains(visible[i]);
      final checkbox = multiSelect
          ? (isChecked
              ? '${theme.checkboxOn}${style.checkboxOnSymbol}${theme.reset}'
              : '${theme.checkboxOff}${style.checkboxOffSymbol}${theme.reset}')
          : ' ';
      final prefix =
          isHighlighted ? '${theme.accent}${style.arrow}${theme.reset}' : ' ';
      final lineText =
          '$prefix $checkbox ${highlightSubstring(visible[i], query, theme, enabled: searchEnabled)}';
      final framePrefix = '${theme.gray}${style.borderVertical}${theme.reset} ';
      if (isHighlighted && style.useInverseHighlight) {
        stdout.writeln('$framePrefix${theme.inverse}$lineText${theme.reset}');
      } else {
        stdout.writeln('$framePrefix$lineText');
      }
    }

    if (filtered.isEmpty) {
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} ${theme.gray}(no matches)${theme.reset}');
    }

    if (style.showBorder) {
      stdout.writeln(frame.bottom());
    }

    final hints = <String>[Hints.hint('↑/↓', 'navigate', theme)];
    if (multiSelect) hints.add(Hints.hint('Space', 'select', theme));
    hints.addAll([
      Hints.hint('Enter', 'confirm', theme),
      Hints.hint('/', 'search', theme),
      Hints.hint('Esc', 'cancel', theme),
    ]);
    stdout.writeln(Hints.bullets(hints, theme));
    Terminal.hideCursor();
  }

  updateFilter();
  render();

  try {
    while (true) {
      final ev = KeyEventReader.read();

      if (ev.type == KeyEventType.enter) break;
      if (ev.type == KeyEventType.ctrlC) {
        cancelled = true;
        break;
      }

      // Space
      if (multiSelect && ev.type == KeyEventType.space && filtered.isNotEmpty) {
        final current = filtered[selectedIndex];
        if (selectedSet.contains(current)) {
          selectedSet.remove(current);
        } else {
          selectedSet.add(current);
        }
      }

      // Toggle search
      else if (ev.type == KeyEventType.slash) {
        searchEnabled = !searchEnabled;
        if (!searchEnabled) query = '';
        updateFilter();
      }

      // Arrows / ESC
      else if (ev.type == KeyEventType.arrowUp ||
          ev.type == KeyEventType.arrowDown ||
          ev.type == KeyEventType.esc) {
        if (ev.type == KeyEventType.arrowUp && filtered.isNotEmpty) {
          selectedIndex =
              (selectedIndex - 1 + filtered.length) % filtered.length;
        } else if (ev.type == KeyEventType.arrowDown && filtered.isNotEmpty) {
          selectedIndex = (selectedIndex + 1) % filtered.length;
        } else if (ev.type == KeyEventType.esc) {
          cancelled = true;
          break;
        }
      }

      // Backspace
      else if (searchEnabled && ev.type == KeyEventType.backspace) {
        if (query.isNotEmpty) {
          query = query.substring(0, query.length - 1);
          updateFilter();
        }
      }

      // Typing
      else if (searchEnabled &&
          ev.type == KeyEventType.char &&
          ev.char != null) {
        query += ev.char!;
        updateFilter();
      }

      // Scroll
      if (selectedIndex < scrollOffset) {
        scrollOffset = selectedIndex;
      } else if (selectedIndex >= scrollOffset + maxVisible) {
        scrollOffset = selectedIndex - maxVisible + 1;
      }

      render();
    }
  } finally {
    cleanup();
  }

  Terminal.clearAndHome();
  Terminal.showCursor();
  if (cancelled || filtered.isEmpty) return [];

  if (multiSelect) {
    if (selectedSet.isEmpty) selectedSet.add(filtered[selectedIndex]);
    return selectedSet.toList();
  } else {
    return [filtered[selectedIndex]];
  }
}
