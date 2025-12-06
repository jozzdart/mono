import 'dart:math';

import '../style/theme.dart';
import '../system/key_events.dart';
import '../system/hints.dart';
import '../system/framed_layout.dart';
import '../system/prompt_runner.dart';
import '../system/terminal.dart';

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
  final style = theme.style;

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
      if (style.useInverseHighlight) {
        return '${theme.inverse}$padded${theme.reset}';
      }
      // Fallback highlight uses selection color
      return '${theme.selection}$padded${theme.reset}';
    }
    return padded;
  }

  void render(RenderOutput out) {
    final frame = FramedLayout(prompt, theme: theme);
    final top = frame.top();
    if (style.boldPrompt) out.writeln('${theme.bold}$top${theme.reset}');

    for (int r = 0; r < rows; r++) {
      final prefix = '${theme.gray}${style.borderVertical}${theme.reset} ';
      final buffer = StringBuffer(prefix);
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
      out.writeln(buffer.toString());

      // Row separator (snap-to-grid line) except after last row
      if (r != rows - 1) {
        final sepPrefix = '${theme.gray}${style.borderVertical}${theme.reset} ';
        final rowLine = List.generate(
          cols,
          (i) => '${theme.gray}${'─' * computedCellWidth}${theme.reset}',
        ).join('${theme.gray}┼${theme.reset}');
        out.writeln('$sepPrefix$rowLine');
      }
    }

    if (style.showBorder) {
      out.writeln(frame.bottom());
    }

    out.writeln(Hints.grid([
      [Hints.key('↑/↓/←/→', theme), 'navigate'],
      if (multiSelect) [Hints.key('Space', theme), 'toggle selection'],
      [Hints.key('Enter', theme), 'confirm'],
      [Hints.key('Esc', theme), 'cancel'],
    ], theme));
  }

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

  int moveLeft(int idx) {
    if (idx == 0) return total - 1;
    return idx - 1;
  }

  int moveRight(int idx) {
    if (idx == total - 1) return 0;
    return idx + 1;
  }

  final runner = PromptRunner(hideCursor: true);
  final result = runner.run(
    render: render,
    onKey: (ev) {
      if (ev.type == KeyEventType.enter) return PromptResult.confirmed;
      if (ev.type == KeyEventType.ctrlC || ev.type == KeyEventType.esc) {
        cancelled = true;
        return PromptResult.cancelled;
      }

      if (multiSelect && ev.type == KeyEventType.space) {
        if (selectedSet.contains(selected)) {
          selectedSet.remove(selected);
        } else {
          selectedSet.add(selected);
        }
      } else if (ev.type == KeyEventType.arrowUp) {
        selected = moveUp(selected);
      } else if (ev.type == KeyEventType.arrowDown) {
        selected = moveDown(selected);
      } else if (ev.type == KeyEventType.arrowLeft) {
        selected = moveLeft(selected);
      } else if (ev.type == KeyEventType.arrowRight) {
        selected = moveRight(selected);
      }

      return null;
    },
  );

  if (cancelled || result == PromptResult.cancelled) return [];

  if (multiSelect) {
    if (selectedSet.isEmpty) selectedSet.add(selected);
    final indices = selectedSet.toList()..sort();
    return indices.map((i) => options[i]).toList();
  }

  return [options[selected]];
}
