import 'dart:math';

import '../style/theme.dart';
import '../system/grid_navigation.dart';
import '../system/key_bindings.dart';
import '../system/prompt_runner.dart';
import '../system/selection_controller.dart';
import '../system/terminal.dart';
import '../system/widget_frame.dart';

/// ChoiceMap – visual dashboard-like grid of options.
///
/// - Arrow keys move across cards (wraps around edges)
/// - Space toggles selection in multi-select mode
/// - Enter confirms
/// - Esc cancels
class ChoiceMapItem {
  final String label;
  final String? subtitle;

  const ChoiceMapItem(this.label, {this.subtitle});
}

class ChoiceMap {
  final List<ChoiceMapItem> items;
  final String prompt;
  final bool multiSelect;
  final PromptTheme theme;
  final int columns; // If <= 0, auto-calc based on terminal width
  final int? cardWidth; // Optional fixed card width; auto if null
  final int? maxColumns; // Optional cap for auto columns

  ChoiceMap(
    this.items, {
    this.prompt = 'Select',
    this.multiSelect = false,
    this.theme = PromptTheme.dark,
    this.columns = 0,
    this.cardWidth,
    this.maxColumns,
  });

  List<String> run() => _choiceMap(
        items,
        prompt: prompt,
        multiSelect: multiSelect,
        theme: theme,
        columns: columns,
        cardWidth: cardWidth,
        maxColumns: maxColumns,
      );
}

List<String> _choiceMap(
  List<ChoiceMapItem> items, {
  String prompt = 'Select',
  bool multiSelect = false,
  PromptTheme theme = PromptTheme.dark,
  int columns = 0,
  int? cardWidth,
  int? maxColumns,
}) {
  if (items.isEmpty) return [];

  // Layout
  final longestLabel = items.fold<int>(0, (m, e) => max(m, e.label.length));
  final longestSubtitle =
      items.fold<int>(0, (m, e) => max(m, (e.subtitle ?? '').length));
  final natural = max(longestLabel + 4, min(36, longestSubtitle + 4));
  final computedCardWidth = (cardWidth ?? natural).clamp(16, 44);

  final int total = items.length;
  int cols = columns;
  if (cols <= 0) {
    final termWidth = TerminalInfo.columns;
    // Prefix left border + space
    const leftPrefix = 2;
    const sepWidth = 1; // vertical separator
    final unit = computedCardWidth + sepWidth;
    final colsByWidth = max(1, ((termWidth - leftPrefix) + sepWidth) ~/ unit);
    final desired = max(2, min(total, (sqrt(total)).ceil()));
    final cap = (maxColumns != null && maxColumns > 0) ? maxColumns : desired;
    cols = min(colsByWidth, cap);
  }
  final rows = (total + cols - 1) ~/ cols;

  // Use GridNavigation for 2D navigation
  final grid = GridNavigation(itemCount: total, columns: cols);

  // Use SelectionController for selection state
  final selection = SelectionController(multiSelect: multiSelect);

  bool cancelled = false;

  // Use KeyBindings for declarative key handling
  final bindings = KeyBindings.gridSelection(
    onUp: () => grid.moveUp(),
    onDown: () => grid.moveDown(),
    onLeft: () => grid.moveLeft(),
    onRight: () => grid.moveRight(),
    onToggle: multiSelect ? () => selection.toggle(grid.focusedIndex) : null,
    showToggleHint: multiSelect,
    onCancel: () => cancelled = true,
  );

  String pad(String text, int width) {
    if (text.length > width) {
      if (width <= 1) return text.substring(0, 1);
      return '${text.substring(0, width - 1)}…';
    }
    return text.padRight(width);
  }

  ({String top, String bottom}) renderCard(
    ChoiceMapItem item, {
    required bool highlighted,
    required bool checked,
  }) {
    final boxWidth = computedCardWidth;
    final check = multiSelect ? (checked ? '[x] ' : '[ ] ') : '';
    final titleMax = boxWidth - (multiSelect ? 4 : 0);
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

  // Use WidgetFrame for consistent frame rendering
  final frame = WidgetFrame(
    title: prompt,
    theme: theme,
    bindings: bindings,
    hintStyle: HintStyle.grid,
  );

  void render(RenderOutput out) {
    frame.render(out, (ctx) {
      final colSep = '${theme.gray}│${theme.reset}';
      for (int r = 0; r < rows; r++) {
        // First line of cards in this row (titles)
        final line1 = StringBuffer(ctx.lb.gutter());
        // Second line (subtitles)
        final line2 = StringBuffer(ctx.lb.gutter());

        for (int c = 0; c < cols; c++) {
          final idx = r * cols + c;
          if (idx >= total) {
            line1.write(''.padRight(computedCardWidth));
            line2.write(''.padRight(computedCardWidth));
          } else {
            final card = renderCard(
              items[idx],
              highlighted: grid.isFocused(idx),
              checked: selection.isSelected(idx),
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
    });
  }

  final runner = PromptRunner(hideCursor: true);
  final result = runner.runWithBindings(
    render: render,
    bindings: bindings,
  );

  if (cancelled || result == PromptResult.cancelled) return [];

  // Use SelectionController's result extraction
  final selectedItems = selection.getSelectedMany(
    items,
    fallbackIndex: grid.focusedIndex,
  );
  return selectedItems.map((item) => item.label).toList();
}
