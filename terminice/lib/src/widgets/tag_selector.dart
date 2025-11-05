import 'dart:io';

import '../style/theme.dart';
import '../system/frame_renderer.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/terminal.dart';

/// TagSelector – choose multiple "chips" (tags) from a list.
///
/// Controls:
/// - Arrow keys navigate between chips
/// - Space toggles selection
/// - Enter confirms
/// - Esc / Ctrl+C cancels (returns empty list)
class TagSelector {
  final List<String> tags;
  final String prompt;
  final PromptTheme theme;
  final int? maxContentWidth; // Optional cap
  final int minContentWidth;
  final int minColumnWidth;
  final int maxColumnWidth;
  final bool useTerminalWidth;

  TagSelector(
    this.tags, {
    this.prompt = 'Select tags',
    this.theme = PromptTheme.dark,
    this.maxContentWidth,
    this.minContentWidth = 32,
    this.minColumnWidth = 8,
    this.maxColumnWidth = 24,
    this.useTerminalWidth = true,
  });

  List<String> run() {
    if (tags.isEmpty) return [];

    final style = theme.style;

    // State
    int focusedIndex = 0;
    final selected = <int>{};
    bool cancelled = false;

    // Terminal
    final term = Terminal.enterRaw();

    void cleanup() {
      term.restore();
      Terminal.showCursor();
    }

    int terminalColumns() {
      try {
        if (stdout.hasTerminal) return stdout.terminalColumns;
      } catch (_) {}
      return 80;
    }

    // Layout calculator for snapping to grid
    ({int contentWidth, int colWidth, int cols, int rows}) layout() {
      // Rough left frame prefix width: border + space
      const framePrefix = 2; // visual columns ignoring color codes

      final termCols = useTerminalWidth ? terminalColumns() : 80;
      final targetContent = (maxContentWidth != null)
          ? maxContentWidth!.clamp(minContentWidth, termCols - 4)
          : (termCols - 4).clamp(minContentWidth, termCols);

      // Determine column width: based on longest tag within sane bounds
      final longest = tags.fold<int>(0, (m, t) => t.length > m ? t.length : m);
      final naturalChip = longest + 4; // [ tag ]
      final colWidth = naturalChip.clamp(minColumnWidth, maxColumnWidth);

      // Compute columns that fit
      final available = targetContent - framePrefix;
      final cols = available <= 0
          ? 1
          : (available + 1) ~/ (colWidth + 1) /* +1 for inter-column space */
              .clamp(1, 99);

      final rows = (tags.length / cols).ceil().clamp(1, 999);
      return (contentWidth: targetContent, colWidth: colWidth, cols: cols, rows: rows);
    }

    String renderChip(int index, bool isFocused, bool isSelected, int colWidth) {
      final base = tags[index];
      final raw = '[ $base ]';
      final padding = (colWidth - raw.length).clamp(0, 1000);
      final padded = raw + ' ' * padding;

      if (isFocused) {
        return '${theme.inverse}${theme.selection}$padded${theme.reset}';
      }
      if (isSelected) {
        // Accentuate text while preserving bracket structure
        final colored = padded.replaceFirst(base, '${theme.accent}$base${theme.reset}');
        return colored;
      }
      return '${theme.dim}$padded${theme.reset}';
    }

    void render() {
      Terminal.clearAndHome();

      final title = style.showBorder
          ? FrameRenderer.titleWithBorders(prompt, theme)
          : FrameRenderer.plainTitle(prompt, theme);
      stdout.writeln(style.boldPrompt ? '${theme.bold}$title${theme.reset}' : title);

      // Selected summary
      final count = selected.length;
      final summary = count == 0
          ? '${theme.dim}(none selected)${theme.reset}'
          : '${theme.accent}$count selected${theme.reset}';
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} ${Hints.comma(['Space to toggle', 'Enter to confirm', 'Esc to cancel'], theme)}  $summary');

      if (style.showBorder) {
        stdout.writeln(FrameRenderer.connectorLine(prompt, theme));
      }

      final l = layout();
      for (var r = 0; r < l.rows; r++) {
        final pieces = <String>[];
        for (var c = 0; c < l.cols; c++) {
          final idx = r * l.cols + c;
          if (idx >= tags.length) break;
          pieces.add(
            renderChip(idx, idx == focusedIndex, selected.contains(idx), l.colWidth),
          );
        }
        stdout.writeln('${theme.gray}${style.borderVertical}${theme.reset} ${pieces.join(' ')}');
      }

      if (style.showBorder) {
        stdout.writeln(FrameRenderer.bottomLine(prompt, theme));
      }

      stdout.writeln(Hints.bullets([
        Hints.hint('←/→/↑/↓', 'navigate', theme),
        Hints.hint('Space', 'toggle', theme),
        Hints.hint('Enter', 'confirm', theme),
        Hints.hint('Esc', 'cancel', theme),
      ], theme));

      Terminal.hideCursor();
    }

    void moveLeft() {
      if (focusedIndex == 0) {
        focusedIndex = tags.length - 1;
      } else {
        focusedIndex -= 1;
      }
    }

    void moveRight() {
      if (focusedIndex == tags.length - 1) {
        focusedIndex = 0;
      } else {
        focusedIndex += 1;
      }
    }

    void moveUp() {
      final l = layout();
      final idx = focusedIndex - l.cols;
      if (idx < 0) {
        // Wrap to same column in last row if exists
        final col = focusedIndex % l.cols;
        final lastRowStart = (l.rows - 1) * l.cols;
        final lastRowLen = tags.length - lastRowStart;
        final targetCol = col.clamp(0, (lastRowLen - 1).clamp(0, l.cols - 1));
        focusedIndex = lastRowStart + targetCol;
      } else {
        focusedIndex = idx;
      }
    }

    void moveDown() {
      final l = layout();
      final idx = focusedIndex + l.cols;
      if (idx >= tags.length) {
        // Wrap to same column in first row
        focusedIndex = focusedIndex % l.cols;
      } else {
        focusedIndex = idx;
      }
    }

    render();

    try {
      while (true) {
        final ev = KeyEventReader.read();

        if (ev.type == KeyEventType.enter) break;
        if (ev.type == KeyEventType.ctrlC || ev.type == KeyEventType.esc) {
          cancelled = true;
          break;
        }

        if (ev.type == KeyEventType.space) {
          if (selected.contains(focusedIndex)) {
            selected.remove(focusedIndex);
          } else {
            selected.add(focusedIndex);
          }
        } else if (ev.type == KeyEventType.arrowLeft) {
          moveLeft();
        } else if (ev.type == KeyEventType.arrowRight) {
          moveRight();
        } else if (ev.type == KeyEventType.arrowUp) {
          moveUp();
        } else if (ev.type == KeyEventType.arrowDown) {
          moveDown();
        }

        render();
      }
    } finally {
      cleanup();
    }

    Terminal.clearAndHome();
    if (cancelled) return [];
    return selected.map((i) => tags[i]).toList(growable: false);
  }
}


