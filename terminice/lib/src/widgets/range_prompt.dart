import 'dart:math' as math;

import '../style/theme.dart';
import '../system/key_bindings.dart';
import '../system/prompt_runner.dart';
import '../system/terminal.dart';
import '../system/widget_frame.dart';

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
  num start = math.min(startInitial, endInitial).clamp(min, max);
  num end = math.max(startInitial, endInitial).clamp(min, max);
  bool editingStart = true;
  bool cancelled = false;

  int valueToIndex(num v, int w) {
    final ratio = (v - min) / (max - min);
    return (ratio * w).round().clamp(0, w);
  }

  String handleGlyph(bool active) => active ? '█' : '█';

  // Use KeyBindings for declarative key handling
  final bindings = KeyBindings([
        // Toggle handle (↑/↓/Space)
        KeyBinding.multi(
          {KeyEventType.arrowUp, KeyEventType.arrowDown, KeyEventType.space},
          (event) {
            editingStart = !editingStart;
            return KeyActionResult.handled;
          },
          hintLabel: '↑/↓/Space',
          hintDescription: 'toggle handle',
        ),
      ]) +
      KeyBindings.horizontalNavigation(
        onLeft: () {
          if (editingStart) {
            start = math.max(min, start - step);
            if (start > end) end = start;
          } else {
            end = math.max(min, end - step);
            if (end < start) start = end;
          }
          start = start.clamp(min, max);
          end = end.clamp(min, max);
        },
        onRight: () {
          if (editingStart) {
            start = math.min(max, start + step);
            if (start > end) end = start;
          } else {
            end = math.min(max, end + step);
            if (end < start) start = end;
          }
          start = start.clamp(min, max);
          end = end.clamp(min, max);
        },
      ) +
      KeyBindings.prompt(onCancel: () => cancelled = true);

  // Use WidgetFrame for consistent frame rendering
  final frame = WidgetFrame(
    title: label,
    theme: theme,
    bindings: bindings,
  );

  void render(RenderOutput out) {
    frame.render(out, (ctx) {
      // Effective width (responsive to terminal columns)
      final effWidth = math.max(10, math.min(width, TerminalInfo.columns - 8));

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
      ctx.line(
          '$border${' ' * (2 + activeIdx)}${theme.accent}^${theme.reset}');
      ctx.line('$border${' ' * (2 + leftPad)}$rangeTxt');

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
      ctx.line(barLine.toString());

      // Active handle label
      ctx.labeledAccent('Active', editingStart ? 'start' : 'end');
    });
  }

  final runner = PromptRunner(hideCursor: true);
  final result = runner.runWithBindings(
    render: render,
    bindings: bindings,
  );

  return (cancelled || result == PromptResult.cancelled)
      ? (startInitial, endInitial)
      : (start, end);
}
