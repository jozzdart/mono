import 'dart:io';

import '../style/theme.dart';
import '../system/terminal.dart';
import '../system/key_events.dart';
import '../system/hints.dart';
import '../system/framed_layout.dart';

/// Star rating prompt (1–5) with theme-aware, colored stars (no emojis).
///
/// Controls:
/// - ← / → adjust
/// - 1–5 set exact value
/// - Enter confirm
/// - Esc cancel (returns initial)
class RatingPrompt {
  final String prompt;
  final int maxStars;
  final int initial;
  final PromptTheme theme;
  final List<String>? labels; // Optional per-star labels

  RatingPrompt(
    this.prompt, {
    this.maxStars = 5,
    this.initial = 3,
    this.theme = PromptTheme.dark,
    this.labels,
  })  : assert(maxStars > 0),
        assert(initial >= 0);

  int run() {
    final style = theme.style;
    int value = initial.clamp(1, maxStars);
    bool cancelled = false;

    final term = Terminal.enterRaw();
    Terminal.hideCursor();

    void cleanup() {
      term.restore();
      Terminal.showCursor();
    }

    String starsLine(int current) {
      final buffer = StringBuffer();
      for (int i = 1; i <= maxStars; i++) {
        final isFilled = i <= current;
        final isCurrent = i == current;
        final color = isCurrent
            ? theme.highlight
            : (isFilled ? theme.accent : theme.gray);
        final glyph = isFilled ? '★' : '☆'; // non-emoji Unicode
        final star = isCurrent ? '${theme.bold}$glyph${theme.reset}' : glyph;
        buffer.write('$color$star${theme.reset}');
        if (i < maxStars) buffer.write(' ');
      }
      return buffer.toString();
    }

    String scaleLine(int current) {
      final buffer = StringBuffer();
      for (int i = 1; i <= maxStars; i++) {
        final color = i == current ? theme.accent : theme.dim;
        buffer.write('$color$i${theme.reset}');
        if (i < maxStars) buffer.write(' ');
      }
      return buffer.toString();
    }

    void render() {
      Terminal.clearAndHome();

      // Title
      final frame = FramedLayout(prompt, theme: theme);
      final top = frame.top();
      if (style.boldPrompt) stdout.writeln('${theme.bold}$top${theme.reset}');

      if (style.showBorder) {
        stdout.writeln(frame.connector());
      }

      // Stars line
      final stars = starsLine(value);
      stdout
          .writeln('${theme.gray}${style.borderVertical}${theme.reset} $stars');

      // Optional label beneath stars (aligned start)
      final effectiveLabels = labels;
      if (effectiveLabels != null && effectiveLabels.length >= maxStars) {
        final label = effectiveLabels[(value - 1).clamp(0, maxStars - 1)];
        stdout.writeln(
            '${theme.gray}${style.borderVertical}${theme.reset} ${theme.dim}Rating:${theme.reset} ${theme.accent}$label${theme.reset}');
      } else {
        // Numeric scale and current value
        final scale = scaleLine(value);
        stdout.writeln(
            '${theme.gray}${style.borderVertical}${theme.reset} $scale   ${theme.dim}(${theme.reset}${theme.accent}$value${theme.reset}${theme.dim}/$maxStars${theme.reset}${theme.dim})${theme.reset}');
      }

      // Bottom border
      if (style.showBorder) {
        stdout.writeln(frame.bottom());
      }

      // Hints (grid layout for clarity)
      frame.printHintsGrid([
        [Hints.key('←/→', theme), 'adjust'],
        ['1–$maxStars', 'set exact'],
        [Hints.key('Enter', theme), 'confirm'],
        [Hints.key('Esc', theme), 'cancel'],
      ]);
    }

    render();

    try {
      while (true) {
        final ev = KeyEventReader.read();

        if (ev.type == KeyEventType.enter) break;
        if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
          cancelled = true;
          break;
        }

        if (ev.type == KeyEventType.arrowLeft) {
          value = (value - 1).clamp(1, maxStars);
        } else if (ev.type == KeyEventType.arrowRight) {
          value = (value + 1).clamp(1, maxStars);
        } else if (ev.type == KeyEventType.char && ev.char != null) {
          final ch = ev.char!;
          if (RegExp(r'^[0-9]$').hasMatch(ch)) {
            final n = int.parse(ch);
            if (n >= 1 && n <= maxStars) value = n;
          }
        }

        render();
      }
    } finally {
      cleanup();
    }

    Terminal.clearAndHome();
    return cancelled ? initial.clamp(1, maxStars) : value.clamp(1, maxStars);
  }
}
