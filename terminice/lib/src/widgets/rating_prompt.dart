import '../style/theme.dart';
import '../system/key_bindings.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

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
    int value = initial.clamp(1, maxStars);

    // Use KeyBindings for declarative, composable key handling
    final bindings = KeyBindings.horizontalNavigation(
          onLeft: () => value = (value - 1).clamp(1, maxStars),
          onRight: () => value = (value + 1).clamp(1, maxStars),
        ) +
        KeyBindings.numbers(
          onNumber: (n) {
            if (n >= 1 && n <= maxStars) value = n;
          },
          max: maxStars,
          hintLabel: '1–$maxStars',
          hintDescription: 'set exact',
        ) +
        KeyBindings.prompt();

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

    // Use WidgetFrame for consistent frame rendering
    final frame = WidgetFrame(
      title: prompt,
      theme: theme,
      bindings: bindings,
      showConnector: true,
      hintStyle: HintStyle.grid,
    );

    void render(RenderOutput out) {
      frame.render(out, (ctx) {
        // Stars line
        final stars = starsLine(value);
        ctx.gutterLine(stars);

        // Optional label beneath stars (aligned start)
        final effectiveLabels = labels;
        if (effectiveLabels != null && effectiveLabels.length >= maxStars) {
          final label = effectiveLabels[(value - 1).clamp(0, maxStars - 1)];
          ctx.labeledAccent('Rating', label);
        } else {
          // Numeric scale and current value
          final scale = scaleLine(value);
          ctx.gutterLine(
              '$scale   ${theme.dim}(${theme.reset}${theme.accent}$value${theme.reset}${theme.dim}/$maxStars${theme.reset}${theme.dim})${theme.reset}');
        }
      });
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: render,
      bindings: bindings,
    );

    return result == PromptResult.cancelled
        ? initial.clamp(1, maxStars)
        : value.clamp(1, maxStars);
  }
}
