import 'dart:io';
import 'dart:math' as math;

import '../style/theme.dart';
import '../system/terminal.dart';
import '../system/key_events.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';

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
  final style = theme.style;
  num value = initial.clamp(min, max);
  bool cancelled = false;

  final term = Terminal.enterRaw();
  Terminal.hideCursor();

  void cleanup() {
    term.restore();
    Terminal.showCursor();
  }

  double easeOutQuad(double t) => 1 - (1 - t) * (1 - t);

  void render({bool pulse = false, bool flare = false}) {
    Terminal.clearAndHome();

    // ─ Top line
    final frame = FramedLayout(label, theme: theme);
    final top = frame.top();
    if (style.boldPrompt) stdout.writeln('${theme.bold}$top${theme.reset}');

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
    final tooltipOffset = 2 + filledLength; // +1 for border, +1 for space
    final paddingLeft = ' ' * tooltipOffset;

    final tooltipText = pulse || flare
        ? '${theme.bold}$percent$unit${theme.reset}'
        : '${theme.dim}$percent$unit${theme.reset}';

    // Render
    // Left border is the vertical line ┃ (or │)
    final border = '${theme.gray}┃${theme.reset}';

    stdout.writeln('$border$paddingLeft$tooltipText');
    stdout.writeln('$border $filledPart$barColor$head${theme.reset}$emptyPart');

    if (style.showBorder) {
      // Only bottom border — no full frame
      final bottom = '${theme.gray}┗${'─' * (width + 2)}${theme.reset}';
      stdout.writeln(bottom);
    }

    // Hints
    stdout.writeln(Hints.bullets([
      Hints.hint('←/→', 'adjust', theme),
      Hints.hint('Enter', 'confirm', theme),
      Hints.hint('Esc', 'cancel', theme),
    ], theme));
  }

  // Entry animation
  for (int i = 0; i <= 10; i++) {
    final t = easeOutQuad(i / 10);
    value = min + (initial - min) * t;
    render();
    sleep(const Duration(milliseconds: 8));
  }

  num prev = value;

  try {
    while (true) {
      final ev = KeyEventReader.read();

      if (ev.type == KeyEventType.enter) break;
      if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
        cancelled = true;
        break;
      }

      if (ev.type == KeyEventType.arrowLeft) {
        value = math.max(min, value - step);
      } else if (ev.type == KeyEventType.arrowRight) {
        value = math.min(max, value + step);
      }

      if (value != prev) {
        prev = value;
        render(pulse: true);
      }
    }
  } finally {
    cleanup();
  }

  // Fast subtle exit shimmer
  for (int i = 0; i < 3; i++) {
    render(pulse: i.isEven);
    sleep(const Duration(milliseconds: 15));
  }

  Terminal.clearAndHome();
  return cancelled ? initial : value;
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
