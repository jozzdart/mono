import 'dart:io';
import 'dart:math';

import '../style/theme.dart';
import '../system/frame_renderer.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/terminal.dart';

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
  final style = theme.style;
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
    final termWidth = stdout.hasTerminal ? stdout.terminalColumns : 80;
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

  // State
  int focused = 0;
  final selected = <int>{};
  bool cancelled = false;

  // Terminal
  final term = Terminal.enterRaw();

  void cleanup() {
    term.restore();
    stdout.write('\x1B[?25h');
  }

  String _pad(String text, int width) {
    if (text.length > width) {
      if (width <= 1) return text.substring(0, 1);
      return text.substring(0, width - 1) + '…';
    }
    return text.padRight(width);
  }

  ({String top, String bottom}) _renderCard(
    ChoiceMapItem item, {
    required bool highlighted,
    required bool checked,
  }) {
    final boxWidth = computedCardWidth;
    final check = multiSelect ? (checked ? '[x] ' : '[ ] ') : '';
    final titleMax = boxWidth - (multiSelect ? 4 : 0);
    final title = _pad(check + item.label, titleMax);
    final subtitle = _pad((item.subtitle ?? ''), boxWidth).trimRight();

    String paint(String s) {
      if (highlighted) {
        if (style.useInverseHighlight)
          return '${theme.inverse}$s${theme.reset}';
        return '${theme.selection}$s${theme.reset}';
      }
      return s;
    }

    final top = paint(title.padRight(boxWidth));
    final bottom =
        paint('${theme.dim}${subtitle.padRight(boxWidth)}${theme.reset}');
    return (top: top, bottom: bottom);
  }

  void render() {
    Terminal.clearAndHome();

    final header = style.showBorder
        ? FrameRenderer.titleWithBorders(prompt, theme)
        : FrameRenderer.plainTitle(prompt, theme);
    stdout.writeln(
        style.boldPrompt ? '${theme.bold}$header${theme.reset}' : header);

    final colSep = '${theme.gray}│${theme.reset}';
    for (int r = 0; r < rows; r++) {
      // First line of cards in this row (titles)
      final prefix = '${theme.gray}${style.borderVertical}${theme.reset} ';
      final line1 = StringBuffer(prefix);
      // Second line (subtitles)
      final line2 = StringBuffer(prefix);

      for (int c = 0; c < cols; c++) {
        final idx = r * cols + c;
        if (idx >= total) {
          line1.write(''.padRight(computedCardWidth));
          line2.write(''.padRight(computedCardWidth));
        } else {
          final card = _renderCard(
            items[idx],
            highlighted: idx == focused,
            checked: selected.contains(idx),
          );
          line1.write(card.top);
          line2.write(card.bottom);
        }
        if (c != cols - 1) {
          line1.write(colSep);
          line2.write(colSep);
        }
      }

      stdout.writeln(line1.toString());
      stdout.writeln(line2.toString());

      if (r != rows - 1) {
        final sepPrefix = '${theme.gray}${style.borderVertical}${theme.reset} ';
        final rowLine = List.generate(
          cols,
          (i) => '${theme.gray}${'─' * computedCardWidth}${theme.reset}',
        ).join('${theme.gray}┼${theme.reset}');
        stdout.writeln('$sepPrefix$rowLine');
      }
    }

    if (style.showBorder) {
      stdout.writeln(FrameRenderer.bottomLine(prompt, theme));
    }

    final rowsHints = <List<String>>[
      [Hints.key('↑/↓/←/→', theme), 'navigate'],
      if (multiSelect) [Hints.key('Space', theme), 'toggle selection'],
      [Hints.key('Enter', theme), 'confirm'],
      [Hints.key('Esc', theme), 'cancel'],
    ];
    stdout.writeln(Hints.grid(rowsHints, theme));
    Terminal.hideCursor();
  }

  int _moveUp(int idx) {
    final col = idx % cols;
    final row = idx ~/ cols;
    var r = row - 1;
    for (int i = 0; i < rows; i++) {
      if (r < 0)
        r = rows - 1;
      else
        r -= 0; // normalize
      final cand = r * cols + col;
      if (cand < total) return cand;
      r -= 1;
    }
    return idx;
  }

  int _moveDown(int idx) {
    final col = idx % cols;
    var r = idx ~/ cols;
    for (int i = 0; i < rows; i++) {
      r = (r + 1) % rows;
      final cand = r * cols + col;
      if (cand < total) return cand;
    }
    return idx;
  }

  int _moveLeft(int idx) => idx == 0 ? total - 1 : idx - 1;
  int _moveRight(int idx) => idx == total - 1 ? 0 : idx + 1;

  render();

  try {
    while (true) {
      final ev = KeyEventReader.read();

      if (ev.type == KeyEventType.enter) break;
      if (ev.type == KeyEventType.ctrlC || ev.type == KeyEventType.esc) {
        cancelled = true;
        break;
      }

      if (multiSelect && ev.type == KeyEventType.space) {
        if (selected.contains(focused)) {
          selected.remove(focused);
        } else {
          selected.add(focused);
        }
      } else if (ev.type == KeyEventType.arrowUp) {
        focused = _moveUp(focused);
      } else if (ev.type == KeyEventType.arrowDown) {
        focused = _moveDown(focused);
      } else if (ev.type == KeyEventType.arrowLeft) {
        focused = _moveLeft(focused);
      } else if (ev.type == KeyEventType.arrowRight) {
        focused = _moveRight(focused);
      }

      render();
    }
  } finally {
    cleanup();
  }

  Terminal.clearAndHome();
  Terminal.showCursor();

  if (cancelled) return [];
  if (multiSelect) {
    if (selected.isEmpty) selected.add(focused);
    final indices = selected.toList()..sort();
    return indices.map((i) => items[i].label).toList();
  }
  return [items[focused].label];
}
