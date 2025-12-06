import 'dart:math';

import '../style/theme.dart';
import '../system/key_bindings.dart';
import '../system/prompt_runner.dart';
import '../system/terminal.dart';
import '../system/widget_frame.dart';

/// 2D grid selection with arrow-key navigation.
///
/// - Arrow keys move across cells (wraps around edges)
/// - Space toggles selection in multi-select mode
/// - Enter confirms
/// - Esc cancels
class GridSelectPrompt {
  final List<String> options;
  final String prompt;
  final int columns; // If <= 0, auto-calc based on terminal width
  final bool multiSelect;
  final PromptTheme theme;
  final int? cellWidth; // Optional fixed width; auto-calculated if null
  final int?
      maxColumns; // Optional cap for auto columns (ensures multi-row on wide terminals)

  GridSelectPrompt(
    this.options, {
    this.prompt = 'Select',
    this.columns = 0,
    this.multiSelect = false,
    this.theme = PromptTheme.dark,
    this.cellWidth,
    this.maxColumns,
  });

  List<String> run() => _gridSelect(
        options,
        prompt: prompt,
        columns: columns,
        multiSelect: multiSelect,
        theme: theme,
        cellWidth: cellWidth,
        maxColumns: maxColumns,
      );
}

List<String> _gridSelect(
  List<String> options, {
  String prompt = 'Select',
  int columns = 0,
  bool multiSelect = false,
  PromptTheme theme = PromptTheme.dark,
  int? cellWidth,
  int? maxColumns,
}) {
  if (options.isEmpty) return [];

  // Layout
  final int total = options.length;

  final int computedCellWidth = cellWidth ??
      (options.fold<int>(0, (w, s) => max(w, s.length)) + 4).clamp(10, 40);

  // Compute columns responsively if not provided or <= 0
  int cols = columns;
  if (cols <= 0) {
    final termWidth = TerminalInfo.columns;
    // Left prefix is "│ " (2 chars). Separator between cells is "│" (1 char).
    const leftPrefix = 2;
    const sepWidth = 1; // between cells
    final unit = computedCellWidth + sepWidth;
    final colsByWidth = max(1, ((termWidth - leftPrefix) + sepWidth) ~/ unit);

    // Aim for a balanced grid roughly sqrt(total), but not exceeding width or explicit cap
    final desired = max(2, min(total, (sqrt(total)).ceil()));
    final cap = (maxColumns != null && maxColumns > 0) ? maxColumns : desired;
    cols = min(colsByWidth, cap);
  }

  final int rows = (total + cols - 1) ~/ cols;
  final String colSep = '${theme.gray}│${theme.reset}';

  // Selection state
  int selected = 0;
  final selectedSet = <int>{};
  bool cancelled = false;

  // Grid navigation helpers
  int moveUp(int idx) {
    final col = idx % cols;
    var row = idx ~/ cols;
    for (int i = 0; i < rows; i++) {
      row = (row - 1 + rows) % rows;
      final cand = row * cols + col;
      if (cand < total) return cand;
    }
    return idx;
  }

  int moveDown(int idx) {
    final col = idx % cols;
    var row = idx ~/ cols;
    for (int i = 0; i < rows; i++) {
      row = (row + 1) % rows;
      final cand = row * cols + col;
      if (cand < total) return cand;
    }
    return idx;
  }

  int moveLeft(int idx) => idx == 0 ? total - 1 : idx - 1;
  int moveRight(int idx) => idx == total - 1 ? 0 : idx + 1;

  // Use KeyBindings for declarative key handling
  final bindings = KeyBindings.gridSelection(
    onUp: () => selected = moveUp(selected),
    onDown: () => selected = moveDown(selected),
    onLeft: () => selected = moveLeft(selected),
    onRight: () => selected = moveRight(selected),
    onToggle: multiSelect
        ? () {
            if (selectedSet.contains(selected)) {
              selectedSet.remove(selected);
            } else {
              selectedSet.add(selected);
            }
          }
        : null,
    showToggleHint: multiSelect,
    onCancel: () => cancelled = true,
  );

  String renderCell(String label,
      {required bool highlighted, required bool checked}) {
    // ASCII-only checkbox to avoid emoji/unicode shapes
    final check = multiSelect ? (checked ? '[x] ' : '[ ] ') : '';

    // Truncate and pad to fit inside the cell
    final maxText = computedCellWidth - (multiSelect ? 4 : 2);
    final visible =
        label.length > maxText ? '${label.substring(0, maxText - 1)}…' : label;
    final padded = (check + visible).padRight(computedCellWidth);

    if (highlighted) {
      if (theme.style.useInverseHighlight) {
        return '${theme.inverse}$padded${theme.reset}';
      }
      // Fallback highlight uses selection color
      return '${theme.selection}$padded${theme.reset}';
    }
    return padded;
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
      for (int r = 0; r < rows; r++) {
        // Use gutter for each row
        final buffer = StringBuffer(ctx.lb.gutter());
        for (int c = 0; c < cols; c++) {
          final idx = r * cols + c;
          if (idx >= total) {
            // Fill empty slots for alignment
            buffer.write(''.padRight(computedCellWidth));
          } else {
            final highlighted = idx == selected;
            final checked = selectedSet.contains(idx);
            buffer.write(renderCell(options[idx],
                highlighted: highlighted, checked: checked));
          }
          if (c != cols - 1) buffer.write(colSep);
        }
        ctx.line(buffer.toString());

        // Row separator (snap-to-grid line) except after last row
        if (r != rows - 1) {
          final rowLine = List.generate(
            cols,
            (i) => '${theme.gray}${'─' * computedCellWidth}${theme.reset}',
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

  if (multiSelect) {
    if (selectedSet.isEmpty) selectedSet.add(selected);
    final indices = selectedSet.toList()..sort();
    return indices.map((i) => options[i]).toList();
  }

  return [options[selected]];
}
