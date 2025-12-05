import 'dart:io' show stdout;
import 'dart:math';

import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/highlighter.dart';
import '../system/prompt_runner.dart';

class HelpDoc {
  final String id;
  final String title;
  final String content;
  final String? category;

  const HelpDoc({
    required this.id,
    required this.title,
    required this.content,
    this.category,
  });
}

/// HelpCenter – searchable doc viewer inside terminal.
///
/// Controls:
/// - Type to search
/// - ↑ / ↓ navigate results
/// - ← / → scroll preview
/// - Backspace erase, Esc cancel
/// - Enter confirm selection (returns selected doc)
class HelpCenter {
  final List<HelpDoc> docs;
  final String title;
  final PromptTheme theme;
  final int maxVisibleResults;
  final int maxPreviewLines;

  HelpCenter({
    required this.docs,
    this.title = 'Help Center',
    this.theme = PromptTheme.dark,
    this.maxVisibleResults = 10,
    this.maxPreviewLines = 8,
  });

  HelpDoc? run() {
    if (docs.isEmpty) return null;

    final style = theme.style;

    String query = '';
    int selectedIndex = 0;
    int listScroll = 0;
    int previewScroll = 0;
    bool cancelled = false;

    List<HelpDoc> filtered = List.from(docs);

    int termCols() {
      try {
        if (stdout.hasTerminal) return stdout.terminalColumns;
      } catch (_) {}
      return 100;
    }

    // Note: compact mode ignores terminal height to avoid expansion

    void updateFilter() {
      if (query.trim().isEmpty) {
        filtered = List.from(docs);
      } else {
        final q = query.toLowerCase();
        filtered = docs
            .where((d) =>
                d.title.toLowerCase().contains(q) ||
                (d.category?.toLowerCase().contains(q) ?? false) ||
                d.content.toLowerCase().contains(q))
            .toList();
        // Light ranking: title hits before content hits
        filtered.sort((a, b) {
          final at = a.title.toLowerCase().contains(q);
          final bt = b.title.toLowerCase().contains(q);
          if (at != bt) return bt ? 1 : -1;
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
      }
      selectedIndex = filtered.isEmpty ? 0 : min(selectedIndex, filtered.length - 1);
      listScroll = 0;
      previewScroll = 0;
    }

    String truncate(String text, int max) {
      if (text.length <= max) return text;
      if (max <= 3) return text.substring(0, max);
      return '${text.substring(0, max - 3)}...';
    }

    String labelFor(HelpDoc d) {
      if (d.category == null || d.category!.isEmpty) return d.title;
      return '${d.title}  ${theme.dim}(${d.category})${theme.reset}';
    }

    void render(RenderOutput out) {
      final cols = termCols();

      final frame = FramedLayout(title, theme: theme);
      final top = frame.top();
      out.writeln(style.boldPrompt ? '${theme.bold}$top${theme.reset}' : top);

      final framePrefix = '${theme.gray}${style.borderVertical}${theme.reset} ';
      out.writeln(
          '$framePrefix${theme.accent}Search:${theme.reset} $query');

      if (style.showBorder) {
        out.writeln(frame.connector());
      }

      // Compact layout: never expand to terminal height. Use caps only.
      final listRows = max(1, min(maxVisibleResults, max(1, filtered.length)));

      // Results header
      final header = '${theme.dim}Results (${filtered.length})${theme.reset}';
      out.writeln('$framePrefix$header');

      // Results window
      if (filtered.isEmpty) {
        out.writeln('$framePrefix${theme.dim}(no matches)${theme.reset}');
      } else {
        final total = filtered.length;
        // Determine if top/bottom ellipses are needed within listRows budget
        final needTop = listScroll > 0;
        final needBottom = (listScroll + listRows) < total;
        final visibleBudget = max(1, listRows - (needTop ? 1 : 0) - (needBottom ? 1 : 0));
        // Compute window indices
        int start = listScroll;
        int count = max(0, min(visibleBudget, total - start));
        // If we don't have enough items to fill, backfill from end
        if (count < visibleBudget) {
          start = max(0, total - visibleBudget);
          count = min(visibleBudget, total - start);
        }
        final end = start + count;
        final showTopEllipsis = start > 0 && listRows > 0;
        final showBottomEllipsis = end < total && listRows > 1;

        int printed = 0;
        if (showTopEllipsis) {
          out.writeln('$framePrefix${theme.dim}...${theme.reset}');
          printed++;
        }

        for (var idx = start; idx < end && printed < listRows - (showBottomEllipsis ? 1 : 0); idx++) {
          final isSel = idx == selectedIndex;
          final prefix = isSel ? '${theme.accent}${style.arrow}${theme.reset}' : ' ';
          final label = labelFor(filtered[idx]);
          final line = '$prefix ${highlightSubstring(label, query, theme)}';
          if (isSel && style.useInverseHighlight) {
            out.writeln('$framePrefix${theme.inverse}$line${theme.reset}');
          } else {
            out.writeln('$framePrefix$line');
          }
          printed++;
        }

        if (showBottomEllipsis && printed < listRows) {
          out.writeln('$framePrefix${theme.dim}...${theme.reset}');
          printed++;
        }
      }

      // Separator to preview
      if (style.showBorder) {
        out.writeln(frame.connector());
      }

      // Preview header
      final selected = filtered.isEmpty
          ? null
          : filtered[selectedIndex];
      final previewTitle = selected == null
          ? '${theme.dim}(no selection)${theme.reset}'
          : '${theme.accent}Preview:${theme.reset} ${selected.title}';
      out.writeln('$framePrefix$previewTitle');

      // Preview content area
      if (selected == null) {
        // Compact: no filler
      } else {
        final rawLines = selected.content.split('\n');
        final viewportStart = min(previewScroll, max(0, rawLines.length - 1));
        final viewportEnd = min(viewportStart + maxPreviewLines, rawLines.length);
        final contentWidth = max(10, cols - 4); // rough padding

        for (var i = viewportStart; i < viewportEnd; i++) {
          final ln = rawLines[i];
          final highlighted = highlightSubstring(truncate(ln, contentWidth), query, theme);
          out.writeln('$framePrefix$highlighted');
        }
        // Compact: no filler beyond content
      }

      if (style.showBorder) {
        out.writeln(frame.bottom());
      }

      out.writeln(Hints.bullets([
        Hints.hint('type', 'search', theme),
        Hints.hint('↑/↓', 'results', theme),
        Hints.hint('←/→', 'scroll preview', theme),
        Hints.hint('Backspace', 'erase', theme),
        Hints.hint('Enter', 'confirm', theme),
        Hints.hint('Esc', 'cancel', theme),
      ], theme));
    }

    void moveSelection(int delta) {
      if (filtered.isEmpty) return;
      final len = filtered.length;
      selectedIndex = (selectedIndex + delta + len) % len;
      if (selectedIndex < listScroll) {
        listScroll = selectedIndex;
      } else if (selectedIndex >= listScroll + maxVisibleResults) {
        listScroll = selectedIndex - maxVisibleResults + 1;
      }
      previewScroll = 0; // reset preview to top of new selection
    }

    updateFilter();

    HelpDoc? result;

    final runner = PromptRunner(hideCursor: true);
    runner.run(
      render: render,
      onKey: (ev) {
        if (ev.type == KeyEventType.ctrlC || ev.type == KeyEventType.esc) {
          cancelled = true;
          return PromptResult.cancelled;
        }

        if (ev.type == KeyEventType.enter) {
          if (filtered.isNotEmpty) result = filtered[selectedIndex];
          return PromptResult.confirmed;
        }

        if (ev.type == KeyEventType.arrowUp) {
          moveSelection(-1);
        } else if (ev.type == KeyEventType.arrowDown) {
          moveSelection(1);
        } else if (ev.type == KeyEventType.arrowLeft) {
          previewScroll = max(0, previewScroll - 1);
        } else if (ev.type == KeyEventType.arrowRight) {
          if (filtered.isNotEmpty) {
            final lines = filtered[selectedIndex].content.split('\n');
            previewScroll = min(previewScroll + 1, max(0, lines.length - 1));
          }
        } else if (ev.type == KeyEventType.backspace) {
          if (query.isNotEmpty) {
            query = query.substring(0, query.length - 1);
            updateFilter();
          }
        } else if (ev.type == KeyEventType.char && ev.char != null) {
          query += ev.char!;
          updateFilter();
        }

        return null;
      },
    );

    return cancelled ? null : result;
  }
}


