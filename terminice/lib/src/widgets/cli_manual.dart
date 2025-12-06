import 'dart:math';

import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/highlighter.dart';
import '../system/list_navigation.dart';
import '../system/prompt_runner.dart';
import '../system/text_input_buffer.dart';
import '../system/text_utils.dart' as text_utils;

class ManualOption {
  final String flag; // e.g. "-f, --force"
  final String description;

  const ManualOption({required this.flag, required this.description});
}

class ManualPage {
  final String name; // e.g. "git"
  final String? section; // e.g. "1"
  final String? synopsis;
  final String? description;
  final List<ManualOption> options;
  final List<String> examples;
  final List<String> seeAlso;

  const ManualPage({
    required this.name,
    this.section,
    this.synopsis,
    this.description,
    this.options = const [],
    this.examples = const [],
    this.seeAlso = const [],
  });
}

/// CLIManual – man-page style docs with live search.
///
/// Controls:
/// - Type to search
/// - ↑ / ↓ navigate results
/// - ← / → scroll manual content
/// - Backspace erase, Esc cancel
/// - Enter confirm selection (returns selected page)
class CLIManual {
  final List<ManualPage> pages;
  final String title;
  final PromptTheme theme;
  final int maxVisibleResults;
  final int width; // fixed width (columns)
  final int height; // fixed height (rows)

  CLIManual({
    required this.pages,
    this.title = 'CLI Manual',
    this.theme = PromptTheme.dark,
    this.maxVisibleResults = 12,
    this.width = 100,
    this.height = 24,
  });

  ManualPage? run() {
    if (pages.isEmpty) return null;

    final style = theme.style;

    // Use centralized text input for search query handling
    final queryInput = TextInputBuffer();
    int pageScroll = 0;
    bool cancelled = false;

    List<ManualPage> filtered = List.from(pages);

    // Use centralized list navigation for selection & scrolling
    final nav = ListNavigation(
      itemCount: filtered.length,
      maxVisible: maxVisibleResults,
    );

    // Fixed-size: do not expand to the full terminal
    int cols0() => width;
    int lines0() => height;

    void updateFilter() {
      if (queryInput.text.trim().isEmpty) {
        filtered = List.from(pages);
      } else {
        final q = queryInput.text.toLowerCase();
        bool matchPage(ManualPage p) {
          if (p.name.toLowerCase().contains(q)) return true;
          if ((p.section ?? '').toLowerCase().contains(q)) return true;
          if ((p.synopsis ?? '').toLowerCase().contains(q)) return true;
          if ((p.description ?? '').toLowerCase().contains(q)) return true;
          for (final opt in p.options) {
            if (opt.flag.toLowerCase().contains(q)) return true;
            if (opt.description.toLowerCase().contains(q)) return true;
          }
          for (final ex in p.examples) {
            if (ex.toLowerCase().contains(q)) return true;
          }
          for (final see in p.seeAlso) {
            if (see.toLowerCase().contains(q)) return true;
          }
          return false;
        }

        filtered = pages.where(matchPage).toList();
        filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      }
      nav.itemCount = filtered.length;
      nav.reset();
      pageScroll = 0;
    }

    List<String> wrap(String text, int width) {
      if (width <= 0) return [text];
      final words = text.split(RegExp(r"\s+"));
      final lines = <String>[];
      var current = StringBuffer();
      for (final w in words) {
        final candidate = current.isEmpty ? w : '$current $w';
        if (text_utils.visibleLength(candidate) <= width) {
          if (current.isEmpty) {
            current.write(w);
          } else {
            current.write(' ');
            current.write(w);
          }
        } else {
          lines.add(current.toString());
          current.clear();
          current.write(w);
        }
      }
      if (current.isNotEmpty) lines.add(current.toString());
      return lines.isEmpty ? [''] : lines;
    }

    List<String> buildManualLines(ManualPage page, int width) {
      final lines = <String>[];

      String header(String h) => '${theme.bold}${theme.accent}$h${theme.reset}';

      // NAME
      lines.add(header('NAME'));
      final shortDesc = (page.description ?? '').split('\n').first;
      final nameLine = page.section == null || page.section!.isEmpty
          ? '${page.name} — $shortDesc'.trim()
          : '${page.name}(${page.section}) — $shortDesc'.trim();
      lines.addAll(wrap(nameLine, width));
      lines.add('');

      // SYNOPSIS
      if ((page.synopsis ?? '').trim().isNotEmpty) {
        lines.add(header('SYNOPSIS'));
        lines.addAll(wrap(page.synopsis!.trim(), width));
        lines.add('');
      }

      // DESCRIPTION
      if ((page.description ?? '').trim().isNotEmpty) {
        lines.add(header('DESCRIPTION'));
        for (final para in (page.description!.trim()).split('\n')) {
          if (para.trim().isEmpty) {
            lines.add('');
          } else {
            lines.addAll(wrap(para.trim(), width));
          }
        }
        lines.add('');
      }

      // OPTIONS
      if (page.options.isNotEmpty) {
        lines.add(header('OPTIONS'));
        final leftWidth = page.options.fold<int>(0,
            (w, o) => max(w, text_utils.visibleLength(o.flag)));
        for (final opt in page.options) {
          final left = opt.flag.padRight(leftWidth + 2);
          final wrapped = wrap(opt.description, max(10, width - (leftWidth + 2)));
          if (wrapped.isEmpty) {
            lines.add(left);
          } else {
            lines.add('$left${wrapped.first}');
            for (var i = 1; i < wrapped.length; i++) {
              lines.add('${' ' * (leftWidth + 2)}${wrapped[i]}');
            }
          }
        }
        lines.add('');
      }

      // EXAMPLES
      if (page.examples.isNotEmpty) {
        lines.add(header('EXAMPLES'));
        for (final ex in page.examples) {
          lines.addAll(wrap(ex, width));
        }
        lines.add('');
      }

      // SEE ALSO
      if (page.seeAlso.isNotEmpty) {
        lines.add(header('SEE ALSO'));
        lines.addAll(wrap(page.seeAlso.join(', '), width));
      }

      return lines;
    }

    void render(RenderOutput out) {
      final cols = cols0();
      final linesCount = lines0();

      final frame = FramedLayout(title, theme: theme);
      final top = frame.top();
      out.writeln(style.boldPrompt ? '${theme.bold}$top${theme.reset}' : top);

      final framePrefix = '${theme.gray}${style.borderVertical}${theme.reset} ';
      out.writeln('$framePrefix${theme.accent}Search:${theme.reset} ${queryInput.text}');

      if (style.showBorder) {
        out.writeln(frame.connector());
      }

      // Fixed layout budgeting: ensure we do not exceed fixed height
      final staticBefore = 1 /*title*/ + 1 /*search*/ + (style.showBorder ? 1 : 0) /*top connector*/ + 1 /*results header*/;
      final staticBetween = (style.showBorder ? 1 : 0) /*separator to preview*/;
      final staticPreviewHeader = 1;
      final staticAfter = (style.showBorder ? 1 : 0) /*bottom*/;

      // First allocate rows to list and preview; hints will consume the remainder.
      int availableRows = max(0, linesCount - (staticBefore + staticBetween + staticPreviewHeader + staticAfter));
      int listRows = max(3, min(maxVisibleResults, availableRows ~/ 2));
      int previewRows = max(3, max(0, availableRows - listRows));

      // Results header
      final headerText = '${theme.dim}Results (${filtered.length})${theme.reset}';
      out.writeln('$framePrefix$headerText');

      // Result window using ListNavigation
      nav.maxVisible = listRows;
      final window = nav.visibleWindow(filtered);

      for (var i = 0; i < window.items.length; i++) {
        final absoluteIdx = window.start + i;
        final isSel = nav.isSelected(absoluteIdx);
        final prefix = isSel ? '${theme.accent}${style.arrow}${theme.reset}' : ' ';
        final label = _labelFor(window.items[i]);
        final line = '$prefix ${highlightSubstring(label, queryInput.text, theme)}';
        if (isSel && style.useInverseHighlight) {
          out.writeln('$framePrefix${theme.inverse}$line${theme.reset}');
        } else {
          out.writeln('$framePrefix$line');
        }
      }

      for (var pad = (window.items.length); pad < listRows; pad++) {
        out.writeln('$framePrefix${theme.dim}·${theme.reset}');
      }

      if (style.showBorder) {
        out.writeln(frame.connector());
      }

      // Preview header
      final selected = filtered.isEmpty ? null : filtered[nav.selectedIndex];
      final previewTitle = selected == null
          ? '${theme.dim}(no selection)${theme.reset}'
          : '${theme.accent}Manual:${theme.reset} ${_labelFor(selected)}';
      out.writeln('$framePrefix$previewTitle');

      // Preview content
      if (selected == null) {
        for (var i = 0; i < previewRows; i++) {
          out.writeln(framePrefix);
        }
      } else {
        final contentWidth = max(10, cols - 4);
        final all = buildManualLines(selected, contentWidth);
        final startLine = min(pageScroll, max(0, all.length - 1));
        final endLine = min(startLine + previewRows, all.length);
        for (var i = startLine; i < endLine; i++) {
          final ln = text_utils.truncate(all[i], contentWidth);
          out.writeln('$framePrefix$ln');
        }
        for (var i = endLine; i < startLine + previewRows; i++) {
          out.writeln(framePrefix);
        }
      }

      if (style.showBorder) {
        out.writeln(frame.bottom());
      }

      // Hints: crop to remaining space to preserve fixed height
      final hintsBlock = Hints.grid([
        [Hints.key('type', theme), 'search'],
        [Hints.key('↑/↓', theme), 'results'],
        [Hints.key('←/→', theme), 'scroll manual'],
        [Hints.key('Backspace', theme), 'erase'],
        [Hints.key('Enter', theme), 'open'],
        [Hints.key('Esc', theme), 'cancel'],
      ], theme);

      final consumed = staticBefore + listRows + staticBetween + staticPreviewHeader + previewRows + staticAfter;
      final remaining = max(0, linesCount - consumed);
      if (remaining > 0) {
        final hintLines = hintsBlock.split('\n');
        final toShow = min(remaining, hintLines.length);
        for (var i = 0; i < toShow; i++) {
          out.writeln(hintLines[i]);
        }
      }
    }

    void moveSelection(int delta) {
      nav.moveBy(delta);
      pageScroll = 0;
    }

    updateFilter();

    ManualPage? result;

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
          pageScroll = max(0, pageScroll - 1);
        } else if (ev.type == KeyEventType.arrowRight) {
          pageScroll = pageScroll + 1;
        } else if (queryInput.handleKey(ev)) {
          // Text input (typing, backspace) - handled by centralized TextInputBuffer
          updateFilter();
        }

        return null;
      },
    );

    return cancelled ? null : result;
  }

  String _labelFor(ManualPage p) {
    final sect = (p.section == null || p.section!.isEmpty) ? '' : '(${p.section})';
    return '${p.name}$sect';
  }
}


