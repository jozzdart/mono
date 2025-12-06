import '../style/theme.dart';
import '../system/prompt_animations.dart';
import '../system/value_prompt.dart';
import '../system/widget_frame.dart';

/// Star rating prompt (1–5) with theme-aware, colored stars (no emojis).
///
/// Controls:
/// - ← / → adjust
/// - 1–5 set exact value
/// - Enter confirm
/// - Esc cancel (returns initial)
///
/// **Implementation:** Uses [AnimatedDiscreteValuePrompt] for core functionality
/// when animations are enabled, demonstrating composition over inheritance.
///
/// **Mixins:** Implements [Animatable] and [Themeable] for fluent configuration:
/// ```dart
/// final rating = RatingPrompt('Rate this')
///   .withFireTheme()          // Theme customization
///   .withQuickAnimations()    // Animation customization
///   .run();
/// ```
///
/// **Example:**
/// ```dart
/// // Basic usage
/// final rating = RatingPrompt('Rate this', initial: 3).run();
///
/// // With theme and animations (fluent API)
/// final rating = RatingPrompt('Rate this')
///   .withPastelTheme()
///   .withSmoothAnimations()
///   .run();
/// ```
class RatingPrompt with Animatable, Themeable {
  final String prompt;
  final int maxStars;
  final int initial;
  @override
  final PromptTheme theme;
  final List<String>? labels; // Optional per-star labels

  /// Whether to show animations (entry/exit/pulse).
  @override
  final bool animated;

  /// Custom animation configuration (overrides [animated]).
  @override
  final PromptAnimations? animations;

  RatingPrompt(
    this.prompt, {
    this.maxStars = 5,
    this.initial = 3,
    this.theme = PromptTheme.dark,
    this.labels,
    this.animated = false,
    this.animations,
  })  : assert(maxStars > 0),
        assert(initial >= 0);

  @override
  RatingPrompt copyWithAnimations({bool? animated, PromptAnimations? animations}) {
    return RatingPrompt(
      prompt,
      maxStars: maxStars,
      initial: initial,
      theme: theme,
      labels: labels,
      animated: animated ?? this.animated,
      animations: animations ?? this.animations,
    );
  }

  @override
  RatingPrompt copyWithTheme(PromptTheme theme) {
    return RatingPrompt(
      prompt,
      maxStars: maxStars,
      initial: initial,
      theme: theme,
      labels: labels,
      animated: animated,
      animations: animations,
    );
  }

  int run() {
    // Use Animatable helper to resolve animation configuration
    final anims = resolveAnimations(PromptAnimations.quick);

    // Use animated prompt if any animation is enabled
    if (anims.entry.enabled || anims.exit.enabled || anims.pulse.enabled) {
      return _runAnimated(anims);
    }

    // Fast path: no animations
    return _runSimple();
  }

  int _runSimple() {
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

  int _runAnimated(PromptAnimations anims) {
    final valuePrompt = AnimatedDiscreteValuePrompt(
      title: prompt,
      maxValue: maxStars,
      initial: initial,
      theme: theme,
      animations: anims,
    );

    return valuePrompt.run(
      render: (ctx, value, max, phase) {
        ctx.animatedStarsDisplay(value, max, phase: phase);
        _renderLabel(ctx, value, max, phase: phase);
      },
    );
  }

  void _renderLabel(
    FrameContext ctx,
    int value,
    int max, {
    AnimationPhase phase = AnimationPhase.normal,
  }) {
    final effectiveLabels = labels;
    if (effectiveLabels != null && effectiveLabels.length >= max) {
      final label = effectiveLabels[(value - 1).clamp(0, max - 1)];

      // Apply pulse styling to label if applicable
      if (phase.isPulsing || (phase.exitFrame?.isPulseOn ?? false)) {
        ctx.gutterLine(
            '${ctx.theme.dim}Rating:${ctx.theme.reset} ${ctx.theme.bold}${ctx.theme.accent}$label${ctx.theme.reset}');
      } else {
        ctx.labeledAccent('Rating', label);
      }
    } else {
      ctx.animatedNumericScale(value, max, phase: phase);
    }
  }
}

// Builder methods (withAnimations, withSmoothAnimations, etc.) are provided
// automatically by the Animatable mixin. See AnimatableBuilder extension.
