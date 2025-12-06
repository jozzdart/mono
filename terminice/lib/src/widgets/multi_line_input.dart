import 'dart:math';
import '../style/theme.dart';
import '../system/key_events.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/line_builder.dart';
import '../system/prompt_runner.dart';

/// MultiLineInputPrompt – editable pseudo text area for multi-line input.
///
/// Controls:
/// - Type normally to insert text
/// - [Enter] inserts a new line
/// - [Backspace] deletes characters or merges lines
/// - [↑]/[↓] navigate between lines
/// - [←]/[→] move within a line
/// - [Ctrl+D] confirm (EOF)
/// - [Esc] or [Ctrl+C] cancel
class MultiLineInputPrompt {
  final String label;
  final PromptTheme theme;
  final int maxLines;
  final int visibleLines;
  final bool allowEmpty;

  MultiLineInputPrompt({
    required this.label,
    this.theme = PromptTheme.dark,
    this.maxLines = 200,
    this.visibleLines = 10,
    this.allowEmpty = true,
  });

  String run() {
    final style = theme.style;

    final lines = <String>[''];
    int cursorLine = 0;
    int cursorColumn = 0;
    int scrollOffset = 0;
    bool cancelled = false;
    bool confirmed = false;

    void render(RenderOutput out) {
      // Use centralized line builder for consistent styling
      final lb = LineBuilder(theme);

      // Header
      final frame = FramedLayout(label, theme: theme);
      final topLine = frame.top();
      out.writeln(
          style.boldPrompt ? '${theme.bold}$topLine${theme.reset}' : topLine);

      // Visible text area
      final start = scrollOffset;
      final end = min(scrollOffset + visibleLines, lines.length);
      for (var i = start; i < end; i++) {
        final text = lines[i];
        final isCurrent = i == cursorLine;
        final prefix = lb.arrow(isCurrent);

        if (isCurrent) {
          final before = text.substring(0, cursorColumn);
          final after = text.substring(cursorColumn);
          final cursorChar = after.isEmpty ? ' ' : after[0];
          out.writeln(
              '${lb.gutter()}$prefix $before${theme.inverse}$cursorChar${theme.reset}${after.length > 1 ? after.substring(1) : ''}');
        } else {
          out.writeln('${lb.gutter()}$prefix $text');
        }
      }

      // Fill remaining lines
      for (var i = end; i < start + visibleLines; i++) {
        out.writeln('${lb.gutterOnly()}   ${theme.dim}~${theme.reset}');
      }

      if (style.showBorder) {
        out.writeln(frame.bottom());
      }

      out.writeln(Hints.bullets([
        Hints.hint('↑/↓', 'line', theme),
        Hints.hint('←/→', 'move', theme),
        Hints.hint('Enter', 'new line', theme),
        Hints.hint('Ctrl+D', 'confirm', theme),
        Hints.hint('Esc', 'cancel', theme),
      ], theme));
    }

    final runner = PromptRunner(hideCursor: true);
    runner.run(
      render: render,
      onKey: (ev) {
        // Cancel
        if (ev.type == KeyEventType.ctrlC || ev.type == KeyEventType.esc) {
          cancelled = true;
          return PromptResult.cancelled;
        }

        // Confirm with Ctrl+D
        if (ev.type == KeyEventType.ctrlD) {
          if (allowEmpty || lines.any((l) => l.trim().isNotEmpty)) {
            confirmed = true;
            return PromptResult.confirmed;
          }
        }

        // Typing
        if (ev.type == KeyEventType.char && ev.char != null) {
          final ch = ev.char!;
          final line = lines[cursorLine];
          final before = line.substring(0, cursorColumn);
          final after = line.substring(cursorColumn);
          lines[cursorLine] = '$before$ch$after';
          cursorColumn++;
        }

        // Backspace
        else if (ev.type == KeyEventType.backspace) {
          if (cursorColumn > 0) {
            final line = lines[cursorLine];
            lines[cursorLine] = line.substring(0, cursorColumn - 1) +
                line.substring(cursorColumn);
            cursorColumn--;
          } else if (cursorLine > 0) {
            // merge with previous line
            final prev = lines[cursorLine - 1];
            final current = lines.removeAt(cursorLine);
            cursorLine--;
            cursorColumn = prev.length;
            lines[cursorLine] = prev + current;
          }
        }

        // Enter = new line
        else if (ev.type == KeyEventType.enter) {
          if (lines.length < maxLines) {
            final line = lines[cursorLine];
            final before = line.substring(0, cursorColumn);
            final after = line.substring(cursorColumn);
            lines[cursorLine] = before;
            lines.insert(cursorLine + 1, after);
            cursorLine++;
            cursorColumn = 0;
          }
        }

        // Vertical movement
        else if (ev.type == KeyEventType.arrowUp) {
          if (cursorLine > 0) cursorLine--;
          cursorColumn = min(cursorColumn, lines[cursorLine].length);
        } else if (ev.type == KeyEventType.arrowDown) {
          if (cursorLine < lines.length - 1) cursorLine++;
          cursorColumn = min(cursorColumn, lines[cursorLine].length);
        }

        // Horizontal movement
        else if (ev.type == KeyEventType.arrowLeft) {
          if (cursorColumn > 0) {
            cursorColumn--;
          } else if (cursorLine > 0) {
            cursorLine--;
            cursorColumn = lines[cursorLine].length;
          }
        } else if (ev.type == KeyEventType.arrowRight) {
          if (cursorColumn < lines[cursorLine].length) {
            cursorColumn++;
          } else if (cursorLine < lines.length - 1) {
            cursorLine++;
            cursorColumn = 0;
          }
        }

        // Scroll if needed
        if (cursorLine < scrollOffset) {
          scrollOffset = cursorLine;
        } else if (cursorLine >= scrollOffset + visibleLines) {
          scrollOffset = cursorLine - visibleLines + 1;
        }

        return null;
      },
    );

    if (cancelled || !confirmed) return '';
    return lines.join('\n');
  }
}
