import '../style/prompt_config.dart';
import '../style/theme.dart';
import '../system/configurable.dart';
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
/// **Configuration:** Uses [Configurable] mixin for unified theme + animation config:
/// ```dart
/// final volume = SliderPrompt('Volume')
///   .withPastelTheme()        // Theme customization
///   .withSmoothAnimations()   // Animation customization
///   .run();
/// ```
///
/// **Config Object:** Also accepts a [PromptConfig] for reusable configuration:
/// ```dart
/// final config = PromptConfig.matrixAnimated();
/// SliderPrompt('Volume', config: config).run();
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
class SliderPrompt with Configurable {
  final String label;
  final num min;
  final num max;
  final num initial;
  final num step;

  /// Width of the slider bar in characters.
  final int width;

  /// Unit suffix for the tooltip (default '%').
  final String unit;

  @override
  final PromptTheme theme;

  @override
  final bool animated;

  @override
  final PromptAnimations? animations;

  /// Creates a slider prompt.
  ///
  /// Accepts either:
  /// - Individual [theme], [animated], [animations] parameters
  /// - A [PromptConfig] object (which takes precedence if provided)
  SliderPrompt(
    this.label, {
    this.min = 0,
    this.max = 100,
    this.initial = 50,
    this.step = 1,
    this.width = 28,
    this.unit = '%',
    // Config object (preferred for reusability)
    PromptConfig? config,
    // Individual parameters (for convenience/backward compatibility)
    PromptTheme theme = PromptTheme.dark,
    bool animated = true,
    PromptAnimations? animations,
  })  : theme = config?.theme ?? theme,
        animated = config?.animated ?? animated,
        animations = config?.animations ?? animations;

  @override
  SliderPrompt copyWith({
    PromptTheme? theme,
    bool? animated,
    PromptAnimations? animations,
  }) {
    return SliderPrompt(
      label,
      min: min,
      max: max,
      initial: initial,
      step: step,
      width: width,
      unit: unit,
      theme: theme ?? this.theme,
      animated: animated ?? this.animated,
      animations: animations ?? this.animations,
    );
  }

  num run() {
    // Use Configurable helper to resolve animation configuration
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
