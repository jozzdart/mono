import '../style/theme.dart';
import '../system/prompt_animations.dart';
import '../system/value_prompt.dart';

/// SliderPrompt – animated slider with smooth entry/exit animations.
///
/// Controls:
/// - ← / → adjust value
/// - Enter confirm
/// - Esc / Ctrl+C cancel (returns initial)
///
/// **Implementation:** Uses [AnimatedValuePrompt] + [PromptAnimations] for
/// composable animation support, demonstrating composition over inheritance.
///
/// **Mixins:** Implements [Animatable] and [Themeable] for fluent configuration:
/// ```dart
/// final volume = SliderPrompt('Volume')
///   .withPastelTheme()        // Theme customization
///   .withSmoothAnimations()   // Animation customization
///   .run();
/// ```
///
/// **Example:**
/// ```dart
/// final volume = SliderPrompt(
///   'Volume',
///   min: 0,
///   max: 100,
///   initial: 50,
/// ).withMatrixTheme().run();
/// ```
class SliderPrompt with Animatable, Themeable {
  final String label;
  final num min;
  final num max;
  final num initial;
  final num step;
  @override
  final PromptTheme theme;

  /// Width of the slider bar in characters.
  final int width;

  /// Unit suffix for the tooltip (default '%').
  final String unit;

  /// Whether to show animations (entry/exit/pulse).
  @override
  final bool animated;

  /// Custom animation configuration (overrides [animated]).
  @override
  final PromptAnimations? animations;

  SliderPrompt(
    this.label, {
    this.min = 0,
    this.max = 100,
    this.initial = 50,
    this.step = 1,
    this.theme = PromptTheme.dark,
    this.width = 28,
    this.unit = '%',
    this.animated = true,
    this.animations,
  });

  @override
  SliderPrompt copyWithAnimations(
      {bool? animated, PromptAnimations? animations}) {
    return SliderPrompt(
      label,
      min: min,
      max: max,
      initial: initial,
      step: step,
      theme: theme,
      width: width,
      unit: unit,
      animated: animated ?? this.animated,
      animations: animations ?? this.animations,
    );
  }

  @override
  SliderPrompt copyWithTheme(PromptTheme theme) {
    return SliderPrompt(
      label,
      min: min,
      max: max,
      initial: initial,
      step: step,
      theme: theme,
      width: width,
      unit: unit,
      animated: animated,
      animations: animations,
    );
  }

  num run() {
    // Use Animatable helper to resolve animation configuration
    final anims = resolveAnimations(PromptAnimations.smooth);

    // Use AnimatedValuePrompt for composable animation support
    final prompt = AnimatedValuePrompt(
      title: label,
      min: min,
      max: max,
      initial: initial,
      step: step,
      theme: theme,
      animations: anims,
    );

    return prompt.run(
      render: (ctx, value, ratio, phase) {
        // Render animated slider bar with tooltip
        ctx.animatedSliderBar(
          ratio,
          phase: phase,
          width: width,
          showTooltip: true,
          unit: unit,
        );
      },
    );
  }
}

// Builder methods (withAnimations, withSmoothAnimations, etc.) are provided
// automatically by the Animatable mixin. See AnimatableBuilder extension.
