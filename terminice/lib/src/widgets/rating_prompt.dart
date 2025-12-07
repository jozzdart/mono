import '../style/prompt_config.dart';
import '../style/theme.dart';
import '../system/configurable.dart';
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
/// **Configuration:** Uses [Configurable] mixin for unified theme + animation config:
/// ```dart
/// final rating = RatingPrompt('Rate this')
///   .withFireTheme()          // Theme customization
///   .withQuickAnimations()    // Animation customization
///   .run();
/// ```
///
/// **Config Object:** Also accepts a [PromptConfig] for reusable configuration:
/// ```dart
/// final config = PromptConfig().withPastelStyle();
/// RatingPrompt('Rate this', config: config).run();
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
class RatingPrompt with Configurable {
  final String prompt;
  final int maxStars;
  final int initial;
  final List<String>? labels; // Optional per-star labels

  @override
  final PromptTheme theme;

  @override
  final bool animated;

  @override
  final PromptAnimations? animations;

  /// Creates a rating prompt.
  ///
  /// Accepts either:
  /// - Individual [theme], [animated], [animations] parameters
  /// - A [PromptConfig] object (which takes precedence if provided)
  RatingPrompt(
    this.prompt, {
    this.maxStars = 5,
    this.initial = 3,
    this.labels,
    // Config object (preferred for reusability)
    PromptConfig? config,
    // Individual parameters (for convenience/backward compatibility)
    PromptTheme theme = PromptTheme.dark,
    bool animated = false,
    PromptAnimations? animations,
  })  : assert(maxStars > 0),
        assert(initial >= 0),
        theme = config?.theme ?? theme,
        animated = config?.animated ?? animated,
        animations = config?.animations ?? animations;

  @override
  RatingPrompt copyWith({
    PromptTheme? theme,
    bool? animated,
    PromptAnimations? animations,
  }) {
    return RatingPrompt(
      prompt,
      maxStars: maxStars,
      initial: initial,
      labels: labels,
      theme: theme ?? this.theme,
      animated: animated ?? this.animated,
      animations: animations ?? this.animations,
    );
  }

  int run() {
    // Use Configurable helper to resolve animation configuration
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
