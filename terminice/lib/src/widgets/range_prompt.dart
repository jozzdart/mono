import 'dart:io' show stdout;
import 'dart:math' as math;

import '../style/theme.dart';
import '../system/key_events.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/prompt_runner.dart';

/// RangePrompt – select a numeric or percent range with two handles.
///
/// Visual, smooth, and aligned with ThemeDemo styling.
///
/// Controls:
/// - ← / → adjust active handle
/// - ↑ / ↓ or Space toggles which handle is active (start/end)
/// - Enter confirms
/// - Esc / Ctrl+C cancels (returns initial values)
class RangePrompt {
  final String label;
  final num min;
  final num max;
  final num startInitial;
  final num endInitial;
  final num step;
  final PromptTheme theme;
  final int width;
  final String unit; // "%" for percent, "" for plain numbers

  RangePrompt(
    this.label, {
    this.min = 0,
    this.max = 100,
    this.startInitial = 20,
    this.endInitial = 80,
    this.step = 1,
    this.theme = PromptTheme.dark,
    this.width = 28,
    this.unit = '%',
  });

  /// Returns the selected range as (start: x, end: y)
  (num start, num end) run() => _rangePrompt(
        label,
        min: min,
        max: max,
        startInitial: startInitial,
        endInitial: endInitial,
        step: step,
        theme: theme,
        width: width,
        unit: unit,
      );
}

(num start, num end) _rangePrompt(
  String label, {
  num min = 0,
  num max = 100,
  num startInitial = 20,
  num endInitial = 80,
  num step = 1,
  PromptTheme theme = PromptTheme.dark,
  int width = 28,
  String unit = '%',
}) {
  final style = theme.style;

  num start = math.min(startInitial, endInitial).clamp(min, max);
  num end = math.max(startInitial, endInitial).clamp(min, max);
  bool editingStart = true;
  bool cancelled = false;

  int valueToIndex(num v, int w) {
    final ratio = (v - min) / (max - min);
    return (ratio * w).round().clamp(0, w);
  }

  String handleGlyph(bool active) => active ? '█' : '█';

  void render(RenderOutput out) {
    // Header
    final frame = FramedLayout(label, theme: theme);
    final top = frame.top();
    final title = style.boldPrompt ? '${theme.bold}$top${theme.reset}' : top;
    out.writeln(title);

    // Effective width (responsive to terminal columns)
    final totalCols = () {
      try {
        return stdout.terminalColumns;
      } catch (_) {
        return 80;
      }
    }();
    final effWidth = math.max(10, math.min(width, totalCols - 8));

    // Compute positions
    final startIdx = valueToIndex(start, effWidth);
    final endIdx = valueToIndex(end, effWidth);

    // Tooltip line (single centered label above the selected range)
    final border = '${theme.gray}┃${theme.reset}';
    final sRaw = (start == start.roundToDouble()
            ? start.toInt().toString()
            : start.toStringAsFixed(1)) +
        unit;
    final eRaw = (end == end.roundToDouble()
            ? end.toInt().toString()
            : end.toStringAsFixed(1)) +
        unit;
    final displayLen = sRaw.length + 1 + eRaw.length; // without color codes
    final centerIdx = ((startIdx + endIdx) / 2).round();
    final leftPad = math.max(0, centerIdx - (displayLen ~/ 2));
    final rangeTxt = '${theme.bold}${theme.accent}$sRaw—$eRaw${theme.reset}';

    // Caret pointer to active handle (visual switch indicator)
    final activeIdx = editingStart ? startIdx : endIdx;
    out.writeln(
        '$border${' ' * (2 + activeIdx)}${theme.accent}^${theme.reset}');
    out.writeln('$border${' ' * (2 + leftPad)}$rangeTxt');

    // Bar with handles
    final startHandle = handleGlyph(editingStart);
    final endHandle = handleGlyph(!editingStart);

    final barLine = StringBuffer();
    barLine.write('$border ');
    for (int i = 0; i <= effWidth; i++) {
      if (i == startIdx) {
        final isActive = editingStart;
        final glyph = isActive
            ? '${theme.inverse}${theme.accent}$startHandle${theme.reset}'
            : '${theme.accent}$startHandle${theme.reset}';
        barLine.write(glyph);
      } else if (i == endIdx) {
        final isActive = !editingStart;
        final glyph = isActive
            ? '${theme.inverse}${theme.accent}$endHandle${theme.reset}'
            : '${theme.accent}$endHandle${theme.reset}';
        barLine.write(glyph);
      } else if (i > startIdx && i < endIdx) {
        barLine.write('${theme.accent}━${theme.reset}');
      } else if (i < effWidth) {
        barLine.write('${theme.dim}·${theme.reset}');
      }
    }
    out.writeln(barLine.toString());

    // Active handle label
    out.writeln(
        '${theme.gray}${style.borderVertical}${theme.reset} Active: ${theme.accent}${editingStart ? 'start' : 'end'}${theme.reset}');

    // Bottom border
    if (style.showBorder) {
      out.writeln(frame.bottom());
    }

    // Hints
    out.writeln(Hints.bullets([
      Hints.hint('↑/↓', 'toggle handle', theme),
      Hints.hint('Space', 'toggle handle', theme),
      Hints.hint('←/→', 'adjust', theme),
      Hints.hint('Enter', 'confirm', theme),
      Hints.hint('Esc', 'cancel', theme),
    ], theme));
  }

  final runner = PromptRunner(hideCursor: true);
  final result = runner.run(
    render: render,
    onKey: (ev) {
      if (ev.type == KeyEventType.enter) return PromptResult.confirmed;
      if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
        cancelled = true;
        return PromptResult.cancelled;
      }

      // Toggle active handle
      if (ev.type == KeyEventType.arrowUp ||
          ev.type == KeyEventType.arrowDown ||
          ev.type == KeyEventType.space) {
        editingStart = !editingStart;
      }

      // Adjust
      else if (ev.type == KeyEventType.arrowLeft) {
        if (editingStart) {
          start = math.max(min, start - step);
          if (start > end) end = start; // keep order
        } else {
          end = math.max(min, end - step);
          if (end < start) start = end; // keep order
        }
      } else if (ev.type == KeyEventType.arrowRight) {
        if (editingStart) {
          start = math.min(max, start + step);
          if (start > end) end = start;
        } else {
          end = math.min(max, end + step);
          if (end < start) start = end;
        }
      }

      // Clamp
      start = start.clamp(min, max);
      end = end.clamp(min, max);
      return null;
    },
  );

  return (cancelled || result == PromptResult.cancelled) ? (startInitial, endInitial) : (start, end);
}
