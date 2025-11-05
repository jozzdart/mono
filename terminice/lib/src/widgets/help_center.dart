import 'dart:io';
import 'dart:math';

import '../style/theme.dart';
import '../system/frame_renderer.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/terminal.dart';
import '../system/highlighter.dart';

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

    int _termCols() {
      try {
        if (stdout.hasTerminal) return stdout.terminalColumns;
      } catch (_) {}
      return 100;
    }

    // Note: compact mode ignores terminal height to avoid expansion

    void _updateFilter() {
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

    String _truncate(String text, int max) {
      if (text.length <= max) return text;
      if (max <= 3) return text.substring(0, max);
      return text.substring(0, max - 3) + '...';
    }

    String _labelFor(HelpDoc d) {
      if (d.category == null || d.category!.isEmpty) return d.title;
      return '${d.title}  ${theme.dim}(${d.category})${theme.reset}';
    }

    void render() {
      Terminal.clearAndHome();

      final cols = _termCols();

      final top = style.showBorder
          ? FrameRenderer.titleWithBorders(title, theme)
          : FrameRenderer.plainTitle(title, theme);
      stdout.writeln(style.boldPrompt ? '${theme.bold}$top${theme.reset}' : top);

      final framePrefix = '${theme.gray}${style.borderVertical}${theme.reset} ';
      stdout.writeln(
          '$framePrefix${theme.accent}Search:${theme.reset} $query');

      if (style.showBorder) {
        stdout.writeln(FrameRenderer.connectorLine(title, theme));
      }

      // Compact layout: never expand to terminal height. Use caps only.
      final listRows = max(1, min(maxVisibleResults, max(1, filtered.length)));

      // Results header
      final header = '${theme.dim}Results (${filtered.length})${theme.reset}';
      stdout.writeln('$framePrefix$header');

      // Results window
      if (filtered.isEmpty) {
        stdout.writeln('$framePrefix${theme.dim}(no matches)${theme.reset}');
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
          stdout.writeln('$framePrefix${theme.dim}...${theme.reset}');
          printed++;
        }

        for (var idx = start; idx < end && printed < listRows - (showBottomEllipsis ? 1 : 0); idx++) {
          final isSel = idx == selectedIndex;
          final prefix = isSel ? '${theme.accent}${style.arrow}${theme.reset}' : ' ';
          final label = _labelFor(filtered[idx]);
          final line = '$prefix ${highlightSubstring(label, query, theme)}';
          if (isSel && style.useInverseHighlight) {
            stdout.writeln('$framePrefix${theme.inverse}$line${theme.reset}');
          } else {
            stdout.writeln('$framePrefix$line');
          }
          printed++;
        }

        if (showBottomEllipsis && printed < listRows) {
          stdout.writeln('$framePrefix${theme.dim}...${theme.reset}');
          printed++;
        }
      }

      // Separator to preview
      if (style.showBorder) {
        stdout.writeln(FrameRenderer.connectorLine(title, theme));
      }

      // Preview header
      final selected = filtered.isEmpty
          ? null
          : filtered[selectedIndex];
      final previewTitle = selected == null
          ? '${theme.dim}(no selection)${theme.reset}'
          : '${theme.accent}Preview:${theme.reset} ${selected.title}';
      stdout.writeln('$framePrefix$previewTitle');

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
          final out = highlightSubstring(_truncate(ln, contentWidth), query, theme);
          stdout.writeln('$framePrefix$out');
        }
        // Compact: no filler beyond content
      }

      if (style.showBorder) {
        stdout.writeln(FrameRenderer.bottomLine(title, theme));
      }

      stdout.writeln(Hints.bullets([
        Hints.hint('type', 'search', theme),
        Hints.hint('↑/↓', 'results', theme),
        Hints.hint('←/→', 'scroll preview', theme),
        Hints.hint('Backspace', 'erase', theme),
        Hints.hint('Enter', 'confirm', theme),
        Hints.hint('Esc', 'cancel', theme),
      ], theme));

      Terminal.hideCursor();
    }

    void _moveSelection(int delta) {
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

    final term = Terminal.enterRaw();
    void cleanup() {
      term.restore();
      Terminal.showCursor();
    }

    _updateFilter();
    render();

    HelpDoc? result;
    try {
      while (true) {
        final ev = KeyEventReader.read();

        if (ev.type == KeyEventType.ctrlC || ev.type == KeyEventType.esc) {
          cancelled = true;
          break;
        }

        if (ev.type == KeyEventType.enter) {
          if (filtered.isNotEmpty) result = filtered[selectedIndex];
          break;
        }

        if (ev.type == KeyEventType.arrowUp) {
          _moveSelection(-1);
        } else if (ev.type == KeyEventType.arrowDown) {
          _moveSelection(1);
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
            _updateFilter();
          }
        } else if (ev.type == KeyEventType.char && ev.char != null) {
          query += ev.char!;
          _updateFilter();
        }

        render();
      }
    } finally {
      cleanup();
    }

    Terminal.clearAndHome();
    return cancelled ? null : result;
  }
}


