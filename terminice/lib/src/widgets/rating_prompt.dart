import '../style/theme.dart';
import '../system/value_prompt.dart';

/// Star rating prompt (1–5) with theme-aware, colored stars (no emojis).
///
/// Controls:
/// - ← / → adjust
/// - 1–5 set exact value
/// - Enter confirm
/// - Esc cancel (returns initial)
///
/// **Implementation:** Uses [DiscreteValuePrompt] for core functionality,
/// demonstrating composition over inheritance.
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
    final valuePrompt = DiscreteValuePrompt(
      title: prompt,
      maxValue: maxStars,
      initial: initial,
      theme: theme,
    );

    return valuePrompt.run(
      render: (ctx, value, max) {
        // Stars display
        ctx.starsDisplay(value, max);

        // Optional label or numeric scale
        final effectiveLabels = labels;
        if (effectiveLabels != null && effectiveLabels.length >= max) {
          final label = effectiveLabels[(value - 1).clamp(0, max - 1)];
          ctx.labeledAccent('Rating', label);
        } else {
          ctx.numericScale(value, max);
        }
      },
    );
  }
}
