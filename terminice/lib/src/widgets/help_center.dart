import 'dart:math';

import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/highlighter.dart';
import '../system/list_navigation.dart';
import '../system/prompt_runner.dart';
import '../system/terminal.dart';
import '../system/text_input_buffer.dart';

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

    // Use centralized text input for search query handling
    final queryInput = TextInputBuffer();
    int previewScroll = 0;
    bool cancelled = false;

    List<HelpDoc> filtered = List.from(docs);

    // Use centralized list navigation for selection & scrolling
    final nav = ListNavigation(
      itemCount: filtered.length,
      maxVisible: maxVisibleResults,
    );

    // Note: compact mode ignores terminal height to avoid expansion

    void updateFilter() {
      if (queryInput.text.trim().isEmpty) {
        filtered = List.from(docs);
      } else {
        final q = queryInput.text.toLowerCase();
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
      nav.itemCount = filtered.length;
      nav.reset();
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
      final cols = TerminalInfo.columns;

      final frame = FramedLayout(title, theme: theme);
      final top = frame.top();
      out.writeln(style.boldPrompt ? '${theme.bold}$top${theme.reset}' : top);

      final framePrefix = '${theme.gray}${style.borderVertical}${theme.reset} ';
      out.writeln('$framePrefix${theme.accent}Search:${theme.reset} ${queryInput.text}');

      if (style.showBorder) {
        out.writeln(frame.connector());
      }

      // Results header
      final header = '${theme.dim}Results (${filtered.length})${theme.reset}';
      out.writeln('$framePrefix$header');

      // Results window using ListNavigation
      if (filtered.isEmpty) {
        out.writeln('$framePrefix${theme.dim}(no matches)${theme.reset}');
      } else {
        final window = nav.visibleWindow(filtered);

        if (window.hasOverflowAbove) {
          out.writeln('$framePrefix${theme.dim}...${theme.reset}');
        }

        for (var i = 0; i < window.items.length; i++) {
          final absoluteIdx = window.start + i;
          final isSel = nav.isSelected(absoluteIdx);
          final prefix =
              isSel ? '${theme.accent}${style.arrow}${theme.reset}' : ' ';
          final label = labelFor(window.items[i]);
          final line = '$prefix ${highlightSubstring(label, queryInput.text, theme)}';
          if (isSel && style.useInverseHighlight) {
            out.writeln('$framePrefix${theme.inverse}$line${theme.reset}');
          } else {
            out.writeln('$framePrefix$line');
          }
        }

        if (window.hasOverflowBelow) {
          out.writeln('$framePrefix${theme.dim}...${theme.reset}');
        }
      }

      // Separator to preview
      if (style.showBorder) {
        out.writeln(frame.connector());
      }

      // Preview header
      final selected = filtered.isEmpty ? null : filtered[nav.selectedIndex];
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
        final viewportEnd =
            min(viewportStart + maxPreviewLines, rawLines.length);
        final contentWidth = max(10, cols - 4); // rough padding

        for (var i = viewportStart; i < viewportEnd; i++) {
          final ln = rawLines[i];
          final highlighted =
              highlightSubstring(truncate(ln, contentWidth), queryInput.text, theme);
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
      nav.moveBy(delta);
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
          if (filtered.isNotEmpty) result = filtered[nav.selectedIndex];
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
            final lines = filtered[nav.selectedIndex].content.split('\n');
            previewScroll = min(previewScroll + 1, max(0, lines.length - 1));
          }
        } else if (queryInput.handleKey(ev)) {
          // Text input (typing, backspace) - handled by centralized TextInputBuffer
          updateFilter();
        }

        return null;
      },
    );

    return cancelled ? null : result;
  }
}
