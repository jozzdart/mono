import 'dart:math' as math;

import '../style/theme.dart';
import '../system/terminal.dart';
import '../system/value_prompt.dart';
import '../system/widget_frame.dart';

/// RangePrompt – select a numeric or percent range with two handles.
///
/// Controls:
/// - ← / → adjust active handle
/// - ↑ / ↓ or Space toggles which handle is active (start/end)
/// - Enter confirms
/// - Esc / Ctrl+C cancels (returns initial values)
///
/// **Example:**
/// ```dart
/// final (start, end) = RangePrompt('Price Range').run();
/// ```
class RangePrompt with Themeable {
  final String label;
  final num min;
  final num max;
  final num startInitial;
  final num endInitial;
  final num step;
  final int width;
  final String unit;

  @override
  final PromptTheme theme;

  /// Creates a range prompt.
  RangePrompt(
    this.label, {
    this.min = 0,
    this.max = 100,
    this.startInitial = 20,
    this.endInitial = 80,
    this.step = 1,
    this.width = 28,
    this.unit = '%',
    this.theme = PromptTheme.dark,
  });

  @override
  RangePrompt copyWithTheme(PromptTheme theme) {
    return RangePrompt(
      label,
      min: min,
      max: max,
      startInitial: startInitial,
      endInitial: endInitial,
      step: step,
      width: width,
      unit: unit,
      theme: theme,
    );
  }

  /// Returns the selected range as (start, end)
  (num start, num end) run() {
    final rangePrompt = RangeValuePrompt(
      title: label,
      min: min,
      max: max,
      startInitial: startInitial,
      endInitial: endInitial,
      step: step,
      theme: theme,
    );

    return rangePrompt.run(
      render: (ctx, start, end, editingStart) {
        _renderBar(ctx, start, end, editingStart);
      },
    );
  }

  void _renderBar(
    FrameContext ctx,
    num start,
    num end,
    bool editingStart,
  ) {
    // Effective width (responsive to terminal columns)
    final effWidth = math.max(10, math.min(width, TerminalInfo.columns - 8));

    int valueToIndex(num v, int w) {
      final ratio = (v - min) / (max - min);
      return (ratio * w).round().clamp(0, w);
    }

    // Compute positions
    final startIdx = valueToIndex(start, effWidth);
    final endIdx = valueToIndex(end, effWidth);

    // Format values
    final sRaw = (start == start.roundToDouble()
            ? start.toInt().toString()
            : start.toStringAsFixed(1)) +
        unit;
    final eRaw = (end == end.roundToDouble()
            ? end.toInt().toString()
            : end.toStringAsFixed(1)) +
        unit;

    // Layout
    final displayLen = sRaw.length + 1 + eRaw.length;
    final centerIdx = ((startIdx + endIdx) / 2).round();
    final leftPad = math.max(0, centerIdx - (displayLen ~/ 2));

    // Range text
    final rangeTxt = '${theme.bold}${theme.accent}$sRaw—$eRaw${theme.reset}';

    final border = '${theme.gray}┃${theme.reset}';
    final activeIdx = editingStart ? startIdx : endIdx;

    // Caret pointer
    ctx.line('$border${' ' * (2 + activeIdx)}${theme.accent}^${theme.reset}');
    ctx.line('$border${' ' * (2 + leftPad)}$rangeTxt');

    // Bar with handles
    final barLine = StringBuffer();
    barLine.write('$border ');
    for (int i = 0; i <= effWidth; i++) {
      if (i == startIdx) {
        final isActive = editingStart;
        String glyph;
        if (isActive) {
          glyph = '${theme.inverse}${theme.accent}█${theme.reset}';
        } else {
          glyph = '${theme.accent}█${theme.reset}';
        }
        barLine.write(glyph);
      } else if (i == endIdx) {
        final isActive = !editingStart;
        String glyph;
        if (isActive) {
          glyph = '${theme.inverse}${theme.accent}█${theme.reset}';
        } else {
          glyph = '${theme.accent}█${theme.reset}';
        }
        barLine.write(glyph);
      } else if (i > startIdx && i < endIdx) {
        barLine.write('${theme.accent}━${theme.reset}');
      } else if (i < effWidth) {
        barLine.write('${theme.dim}·${theme.reset}');
      }
    }
    ctx.line(barLine.toString());

    // Active indicator
    final activeLabel = editingStart ? 'start' : 'end';
    ctx.labeledAccent('Active', activeLabel);
  }
}
