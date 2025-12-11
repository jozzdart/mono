import 'package:terminice/terminice.dart';

/// SliderPrompt – slider for continuous value selection.
///
/// Controls:
/// - ← / → adjust value
/// - Enter confirm
/// - Esc / Ctrl+C cancel (returns initial)
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
class SliderPrompt with Themeable {
  final String label;
  final num min;
  final num max;
  final num initial;
  final num step;

  /// Width of the slider bar in characters.
  final int width;

  /// Unit suffix for display (default '%').
  final String unit;

  @override
  final PromptTheme theme;

  /// Creates a slider prompt.
  SliderPrompt(
    this.label, {
    this.min = 0,
    this.max = 100,
    this.initial = 50,
    this.step = 1,
    this.width = 28,
    this.unit = '%',
    this.theme = PromptTheme.dark,
  });

  @override
  SliderPrompt copyWithTheme(PromptTheme theme) {
    return SliderPrompt(
      label,
      min: min,
      max: max,
      initial: initial,
      step: step,
      width: width,
      unit: unit,
      theme: theme,
    );
  }

  num run() {
    final prompt = ValuePrompt(
      title: label,
      min: min,
      max: max,
      initial: initial,
      step: step,
      theme: theme,
    );

    return prompt.run(
      render: (ctx, value, ratio) {
        ctx.sliderBar(ratio, width: width, showPercent: true);
      },
    );
  }
}

extension SliderPromptExtensions on Terminice {
  /// Slider prompt for selecting a numeric value.
  ///
  /// Returns the selected value.
  ///
  /// **Example:**
  /// ```dart
  /// final volume = terminice.slider('Volume', initial: 50);
  /// ```
  num slider(
    String label, {
    num min = 0,
    num max = 100,
    num initial = 50,
    num step = 1,
    int width = 28,
    String unit = '%',
    PromptTheme? theme,
  }) {
    return SliderPrompt(
      label,
      min: min,
      max: max,
      initial: initial,
      step: step,
      width: width,
      unit: unit,
      theme: theme ?? defaultTheme,
    ).run();
  }
}
