import 'dart:io';

import '../style/theme.dart';
import '../system/frame_renderer.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/terminal.dart';

/// CheckboxMenu – vertical multi-select checklist with live summary counter.
///
/// Controls:
/// - ↑ / ↓ navigate
/// - Space toggle selection
/// - A select all / clear all
/// - Enter confirm
/// - Esc / Ctrl+C cancel (returns empty list)
class CheckboxMenu {
  final String label;
  final List<String> options;
  final PromptTheme theme;
  final int maxVisible; // soft cap; may reduce based on terminal size
  final Set<int> initialSelected;

  CheckboxMenu({
    required this.label,
    required this.options,
    this.theme = PromptTheme.dark,
    this.maxVisible = 12,
    Set<int>? initialSelected,
  }) : initialSelected = {...(initialSelected ?? const <int>{})};

  List<String> run() {
    if (options.isEmpty) return <String>[];

    final style = theme.style;

    // State
    int focused = 0;
    int scroll = 0;
    int visibleRows = maxVisible;
    final selected = <int>{
      ...initialSelected.where((i) => i >= 0 && i < options.length)
    };
    bool cancelled = false;

    int termCols() {
      try {
        if (stdout.hasTerminal) return stdout.terminalColumns;
      } catch (_) {}
      return 100;
    }

    int termLines() {
      try {
        if (stdout.hasTerminal) return stdout.terminalLines;
      } catch (_) {}
      return 28;
    }

    void move(int delta) {
      if (options.isEmpty) return;
      final len = options.length;
      focused = (focused + delta + len) % len;
      // maintain focus within viewport
      if (focused < scroll) {
        scroll = focused;
      } else if (focused >= scroll + visibleRows) {
        scroll = focused - visibleRows + 1;
      }
    }

    void toggle(int index) {
      if (index < 0 || index >= options.length) return;
      if (selected.contains(index)) {
        selected.remove(index);
      } else {
        selected.add(index);
      }
    }

    void selectAllOrClear() {
      if (selected.length == options.length) {
        selected.clear();
      } else {
        selected
          ..clear()
          ..addAll(List<int>.generate(options.length, (i) => i));
      }
    }

    String checkbox(bool isOn) {
      final sym = isOn ? style.checkboxOnSymbol : style.checkboxOffSymbol;
      final col = isOn ? theme.checkboxOn : theme.checkboxOff;
      return '$col$sym${theme.reset}';
    }

    String summaryLine() {
      final total = options.length;
      final count = selected.length;
      if (count == 0) {
        return '${theme.dim}(none selected)${theme.reset}';
      }
      // render up to 3 selections by label, then "+N"
      final indices = selected.toList()..sort();
      final names = <String>[];
      for (var i = 0; i < indices.length && i < 3; i++) {
        final name = options[indices[i]];
        names.add('${theme.accent}$name${theme.reset}');
      }
      final more = indices.length > 3
          ? ' ${theme.dim}(+${indices.length - 3})${theme.reset}'
          : '';
      return '${theme.accent}$count${theme.reset}/${theme.dim}$total${theme.reset} • ${names.join('${theme.dim}, ${theme.reset}')} $more';
    }

    void render() {
      Terminal.clearAndHome();

      // Responsive rows from terminal lines: reserve around 7 for chrome/hints
      final lines = termLines();
      visibleRows = (lines - 7).clamp(5, maxVisible);

      final title = style.showBorder
          ? FrameRenderer.titleWithBorders(label, theme)
          : FrameRenderer.plainTitle(label, theme);
      stdout.writeln(
          style.boldPrompt ? '${theme.bold}$title${theme.reset}' : title);

      // Summary line
      final prefix = '${theme.gray}${style.borderVertical}${theme.reset} ';
      stdout.writeln(prefix + summaryLine());

      if (style.showBorder) {
        stdout.writeln(FrameRenderer.connectorLine(label, theme));
      }

      // Compute viewport
      var end = scroll + visibleRows;
      if (end > options.length) end = options.length;
      final visible = options.sublist(scroll, end);

      // Optional overflow indicator (top)
      if (scroll > 0 && visible.isNotEmpty) {
        stdout.writeln(
            '${theme.gray}${style.borderVertical}${theme.reset} ${theme.dim}...${theme.reset}');
      }

      final cols = termCols();
      for (var i = 0; i < visible.length; i++) {
        final idx = scroll + i;
        final isFocused = idx == focused;
        final isChecked = selected.contains(idx);

        final check = checkbox(isChecked);
        final arrow =
            isFocused ? '${theme.accent}${style.arrow}${theme.reset}' : ' ';
        final framePrefix =
            '${theme.gray}${style.borderVertical}${theme.reset} ';

        // Construct core line and fit within terminal width with graceful truncation
        var core = '$arrow $check ${options[idx]}';
        final reserve = 0; // no trailing widget for now
        final maxLabel =
            (cols - framePrefix.length - 1 - reserve).clamp(8, cols);
        if (core.length > maxLabel) {
          core = '${core.substring(0, maxLabel - 3)}...';
        }

        if (isFocused && style.useInverseHighlight) {
          stdout.writeln('$framePrefix${theme.inverse}$core${theme.reset}');
        } else {
          stdout.writeln('$framePrefix$core');
        }
      }

      // Optional overflow indicator (bottom)
      if (end < options.length && visible.isNotEmpty) {
        stdout.writeln(
            '${theme.gray}${style.borderVertical}${theme.reset} ${theme.dim}...${theme.reset}');
      }

      if (style.showBorder) {
        stdout.writeln(FrameRenderer.bottomLine(label, theme));
      }

      // Hints (aligned grid)
      stdout.writeln(Hints.grid([
        [Hints.key('↑/↓', theme), 'navigate'],
        [Hints.key('Space', theme), 'toggle'],
        [Hints.key('A', theme), 'select all / clear'],
        [Hints.key('Enter', theme), 'confirm'],
        [Hints.key('Esc', theme), 'cancel'],
      ], theme));

      Terminal.hideCursor();
    }

    final term = Terminal.enterRaw();
    void cleanup() {
      term.restore();
      Terminal.showCursor();
    }

    // Initial render
    render();

    try {
      while (true) {
        final ev = KeyEventReader.read();

        if (ev.type == KeyEventType.ctrlC) {
          cancelled = true;
          break;
        }

        if (ev.type == KeyEventType.arrowUp) {
          move(-1);
        } else if (ev.type == KeyEventType.arrowDown) {
          move(1);
        } else if (ev.type == KeyEventType.space) {
          toggle(focused);
        } else if (ev.type == KeyEventType.char && ev.char != null) {
          final ch = ev.char!;
          if (ch.toLowerCase() == 'a') {
            selectAllOrClear();
          }
        } else if (ev.type == KeyEventType.esc) {
          cancelled = true;
          break;
        } else if (ev.type == KeyEventType.enter) {
          break;
        }

        render();
      }
    } finally {
      cleanup();
    }

    Terminal.clearAndHome();
    if (cancelled) return <String>[];
    if (selected.isEmpty) selected.add(focused);
    final out = selected.toList()..sort();
    return out.map((i) => options[i]).toList(growable: false);
  }
}
