import '../style/theme.dart';
import '../system/value_prompt.dart';
import '../system/widget_frame.dart';

/// Star rating prompt (1–5) with theme-aware, colored stars.
///
/// Controls:
/// - ← / → adjust
/// - 1–5 set exact value
/// - Enter confirm
/// - Esc cancel (returns initial)
///
/// **Example:**
/// ```dart
/// final rating = RatingPrompt('Rate this', initial: 3).run();
/// ```
class RatingPrompt with Themeable {
  final String prompt;
  final int maxStars;
  final int initial;
  final List<String>? labels;

  @override
  final PromptTheme theme;

  /// Creates a rating prompt.
  RatingPrompt(
    this.prompt, {
    this.maxStars = 5,
    this.initial = 3,
    this.labels,
    this.theme = PromptTheme.dark,
  }) : assert(maxStars > 0),
       assert(initial >= 0);

  @override
  RatingPrompt copyWithTheme(PromptTheme theme) {
    return RatingPrompt(
      prompt,
      maxStars: maxStars,
      initial: initial,
      labels: labels,
      theme: theme,
    );
  }

  int run() {
    final valuePrompt = DiscreteValuePrompt(
      title: prompt,
      maxValue: maxStars,
      initial: initial,
      theme: theme,
    );

    return valuePrompt.run(
      render: (ctx, value, max) {
        ctx.starsDisplay(value, max);
        _renderLabel(ctx, value, max);
      },
    );
  }

  void _renderLabel(FrameContext ctx, int value, int max) {
    final effectiveLabels = labels;
    if (effectiveLabels != null && effectiveLabels.length >= max) {
      final label = effectiveLabels[(value - 1).clamp(0, max - 1)];
        ctx.labeledAccent('Rating', label);
    } else {
      ctx.numericScale(value, max);
    }
  }
}
