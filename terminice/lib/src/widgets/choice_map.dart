import 'dart:math';

import '../style/theme.dart';
import '../system/selectable_grid_prompt.dart';
import '../system/terminal.dart';

/// ChoiceMapItem – a card with label and optional subtitle.
class ChoiceMapItem {
  final String label;
  final String? subtitle;

  const ChoiceMapItem(this.label, {this.subtitle});
}

/// ChoiceMap – visual dashboard-like grid of option cards.
///
/// Controls:
/// - Arrow keys move across cards (wraps around edges)
/// - Space toggles selection in multi-select mode
/// - Enter confirms
/// - Esc cancels
///
/// **Implementation:** Uses [SelectableGridPrompt] for core functionality,
/// demonstrating composition over inheritance.
class ChoiceMap {
  final List<ChoiceMapItem> items;
  final String prompt;
  final bool multiSelect;
  final PromptTheme theme;
  final int columns; // If <= 0, auto-calc
  final int? cardWidth;
  final int? maxColumns;

  ChoiceMap(
    this.items, {
    this.prompt = 'Select',
    this.multiSelect = false,
    this.theme = PromptTheme.dark,
    this.columns = 0,
    this.cardWidth,
    this.maxColumns,
  });

  List<String> run() {
    if (items.isEmpty) return [];

    // Compute card layout
    final longestLabel = items.fold<int>(0, (m, e) => max(m, e.label.length));
    final longestSubtitle =
        items.fold<int>(0, (m, e) => max(m, (e.subtitle ?? '').length));
    final natural = max(longestLabel + 4, min(36, longestSubtitle + 4));
    final computedCardWidth = (cardWidth ?? natural).clamp(16, 44);

    int computeCols() {
      if (columns > 0) return columns;
      final termWidth = TerminalInfo.columns;
      const leftPrefix = 2;
      const sepWidth = 1;
      final unit = computedCardWidth + sepWidth;
      final colsByWidth = max(1, ((termWidth - leftPrefix) + sepWidth) ~/ unit);
      final desired = max(2, min(items.length, sqrt(items.length).ceil()));
      final cap = (maxColumns != null && maxColumns! > 0) ? maxColumns! : desired;
      return min(colsByWidth, cap);
    }

    final cols = computeCols();
    final rows = (items.length + cols - 1) ~/ cols;

    // Use SelectableGridPrompt with custom card rendering
    final gridPrompt = SelectableGridPrompt<ChoiceMapItem>(
      title: prompt,
      items: items,
      theme: theme,
      multiSelect: multiSelect,
      columns: cols,
      cellWidth: computedCardWidth,
      maxColumns: maxColumns,
    );

    // Run with custom card-style rendering (two lines per card)
    final result = gridPrompt.runCustom(
      renderContent: (ctx) {
        final colSep = '${theme.gray}│${theme.reset}';

        for (int r = 0; r < rows; r++) {
          // First line of cards (titles)
          final line1 = StringBuffer(ctx.lb.gutter());
          // Second line (subtitles)
          final line2 = StringBuffer(ctx.lb.gutter());

          for (int c = 0; c < cols; c++) {
            final idx = r * cols + c;
            if (idx >= items.length) {
              line1.write(''.padRight(computedCardWidth));
              line2.write(''.padRight(computedCardWidth));
            } else {
              final card = _renderCard(
                items[idx],
                computedCardWidth,
                gridPrompt.grid.isFocused(idx),
                gridPrompt.selection.isSelected(idx),
              );
              line1.write(card.top);
              line2.write(card.bottom);
            }
            if (c != cols - 1) {
              line1.write(colSep);
              line2.write(colSep);
            }
          }

          ctx.line(line1.toString());
          ctx.line(line2.toString());

          if (r != rows - 1) {
            final rowLine = List.generate(
              cols,
              (i) => '${theme.gray}${'─' * computedCardWidth}${theme.reset}',
            ).join('${theme.gray}┼${theme.reset}');
            ctx.gutterLine(rowLine);
          }
        }
      },
    );

    return result.map((item) => item.label).toList();
  }

  ({String top, String bottom}) _renderCard(
    ChoiceMapItem item,
    int boxWidth,
    bool highlighted,
    bool checked,
  ) {
    final check = multiSelect ? (checked ? '[x] ' : '[ ] ') : '';
    final titleMax = boxWidth - (multiSelect ? 4 : 0);

    String pad(String text, int width) {
      if (text.length > width) {
        if (width <= 1) return text.substring(0, 1);
        return '${text.substring(0, width - 1)}…';
      }
      return text.padRight(width);
    }

    final title = pad(check + item.label, titleMax);
    final subtitle = pad((item.subtitle ?? ''), boxWidth).trimRight();

    String paint(String s) {
      if (highlighted) {
        if (theme.style.useInverseHighlight) {
          return '${theme.inverse}$s${theme.reset}';
        }
        return '${theme.selection}$s${theme.reset}';
      }
      return s;
    }

    final top = paint(title.padRight(boxWidth));
    final bottom =
        paint('${theme.dim}${subtitle.padRight(boxWidth)}${theme.reset}');
    return (top: top, bottom: bottom);
  }
}
