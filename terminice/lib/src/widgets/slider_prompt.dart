import 'dart:io' show sleep;
import 'dart:math' as math;

import '../style/theme.dart';
import '../system/key_bindings.dart';
import '../system/key_events.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

/// ⚡ Ultra-fast slider with left border and percent above the head.
class SliderPrompt {
  final String label;
  final num min;
  final num max;
  final num initial;
  final num step;
  final PromptTheme theme;

  SliderPrompt(
    this.label, {
    this.min = 0,
    this.max = 100,
    this.initial = 50,
    this.step = 1,
    this.theme = PromptTheme.dark,
  });

  num run() => _sliderPrompt(
        label,
        min: min,
        max: max,
        initial: initial,
        step: step,
        theme: theme,
      );
}

num _sliderPrompt(
  String label, {
  num min = 0,
  num max = 100,
  num initial = 50,
  num step = 1,
  PromptTheme theme = PromptTheme.dark,
  int width = 28,
  String unit = '%',
}) {
  final runner = PromptRunner(hideCursor: true);

  return runner.runCustom((out) {
    num value = initial.clamp(min, max);
    bool cancelled = false;

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings.slider(
      onLeft: () => value = math.max(min, value - step),
      onRight: () => value = math.min(max, value + step),
      onCancel: () => cancelled = true,
    );

    double easeOutQuad(double t) => 1 - (1 - t) * (1 - t);

    // Use WidgetFrame for consistent rendering
    final frame = WidgetFrame(
      title: label,
      theme: theme,
      bindings: bindings,
      hintStyle: HintStyle.bullets,
    );

    void render({bool pulse = false, bool flare = false}) {
      frame.render(out, (ctx) {
        // Calculate bar state
        final ratio = (value - min) / (max - min);
        final filledLength = (ratio * width).round().clamp(0, width);
        final percent = (ratio * 100).round();

        // Gradient shades
        final shades = ['░', '▒', '▓', '█'];
        final shade = shades[(ratio * (shades.length - 1)).clamp(0, 3).round()];

        final barColor = flare
            ? theme.bold
            : pulse
                ? theme.bold
                : theme.accent;

        final filledPart =
            '$barColor${shade * math.max(0, filledLength)}${theme.reset}';
        final emptyPart =
            '${theme.dim}${'·' * (width - filledLength)}${theme.reset}';

        final head = _sliderHead(percent, pulse, flare);

        // Tooltip directly above head (no arrow)
        final tooltipOffset = filledLength;
        final paddingLeft = ' ' * tooltipOffset;

        final tooltipText = pulse || flare
            ? '${theme.bold}$percent$unit${theme.reset}'
            : '${theme.dim}$percent$unit${theme.reset}';

        // Render tooltip and bar using gutter lines
        ctx.gutterLine('$paddingLeft$tooltipText');
        ctx.gutterLine('$filledPart$barColor$head${theme.reset}$emptyPart');
      });
    }

    // Entry animation
    for (int i = 0; i <= 10; i++) {
      final t = easeOutQuad(i / 10);
      value = min + (initial - min) * t;
      out.clear();
      render();
      sleep(const Duration(milliseconds: 8));
    }

    num prev = value;

    // Main input loop - using KeyBindings for handling
    while (true) {
      final ev = KeyEventReader.read();
      final result = bindings.handle(ev);

      if (result == KeyActionResult.confirmed) break;
      if (result == KeyActionResult.cancelled) break;

      if (value != prev) {
        prev = value;
        out.clear();
        render(pulse: true);
      }
    }

    // Fast subtle exit shimmer
    for (int i = 0; i < 3; i++) {
      out.clear();
      render(pulse: i.isEven);
      sleep(const Duration(milliseconds: 15));
    }

    return cancelled ? initial : value;
  });
}

/// Slider head styling.
String _sliderHead(int percent, bool pulse, bool flare) {
  if (flare) return '★';
  if (pulse) return '⦿';
  if (percent < 25) return '◉';
  if (percent < 50) return '◎';
  if (percent < 75) return '●';
  if (percent < 90) return '⦾';
  return '★';
}
