import '../style/theme.dart';
import 'prompt_animations.dart';

// ============================================================================
// CONFIGURABLE MIXIN – Unified builder pattern for theme + animation support
// ============================================================================

/// Mixin that combines `Themeable` and `Animatable` with a single copyWith.
///
/// **Problem it solves:**
/// Widgets that support both themes AND animations must implement TWO methods:
/// ```dart
/// // Before Configurable – TWO methods required
/// class MyPrompt with Animatable, Themeable {
///   @override
///   MyPrompt copyWithTheme(PromptTheme theme) { /* rebuild */ }
///   @override
///   MyPrompt copyWithAnimations({bool? animated, PromptAnimations? animations}) { /* rebuild */ }
/// }
/// ```
///
/// **After Configurable:**
/// ```dart
/// // After – ONE method handles everything
/// class MyPrompt with Configurable {
///   @override
///   MyPrompt copyWith({PromptTheme? theme, bool? animated, PromptAnimations? animations}) {
///     return MyPrompt(
///       theme: theme ?? this.theme,
///       animated: animated ?? this.animated,
///       animations: animations ?? this.animations,
///     );
///   }
/// }
/// ```
///
/// **Benefits:**
/// - **DRY**: Single method instead of two
/// - **Scalable**: Easy to add new config options (just add parameters)
/// - **Composable**: Still works with `ThemeableBuilder` and `AnimatableBuilder`
/// - **Type-safe**: Builder methods return the correct concrete type
///
/// **All builder methods available:**
/// ```dart
/// final result = SliderPrompt('Volume')
///   // Theme methods (from Themeable/ThemeableBuilder)
///   .withTheme(customTheme)
///   .withDarkTheme()
///   .withMatrixTheme()
///   .withFireTheme()
///   .withPastelTheme()
///   // Animation methods (from Animatable/AnimatableBuilder)
///   .withAnimations()
///   .withoutAnimations()
///   .withQuickAnimations()
///   .withSmoothAnimations()
///   .withFlashyAnimations()
///   .withCustomAnimations(custom)
///   // Combined method (from ConfigurableBuilder)
///   .configured(theme: custom, animated: true)
///   .run();
/// ```
mixin Configurable implements Themeable, Animatable {
  /// The current theme.
  @override
  PromptTheme get theme;

  /// Whether animations are enabled.
  @override
  bool get animated;

  /// Custom animation configuration.
  @override
  PromptAnimations? get animations;

  /// Creates a copy with any combination of new settings.
  ///
  /// This is the ONLY method implementers need to define.
  /// All builder methods delegate to this.
  ///
  /// Use null to preserve existing values:
  /// ```dart
  /// copyWith(theme: newTheme) // only changes theme
  /// copyWith(animated: true)  // only changes animated
  /// copyWith(theme: newTheme, animated: true) // changes both
  /// ```
  Configurable copyWith({
    PromptTheme? theme,
    bool? animated,
    PromptAnimations? animations,
  });

  // ────────────────────────────────────────────────────────────────────────────
  // THEMEABLE IMPLEMENTATION
  // ────────────────────────────────────────────────────────────────────────────

  /// Implements [Themeable.copyWithTheme] by delegating to [copyWith].
  @override
  Configurable copyWithTheme(PromptTheme theme) {
    return copyWith(theme: theme);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // ANIMATABLE IMPLEMENTATION
  // ────────────────────────────────────────────────────────────────────────────

  /// Implements [Animatable.copyWithAnimations] by delegating to [copyWith].
  @override
  Configurable copyWithAnimations({
    bool? animated,
    PromptAnimations? animations,
  }) {
    return copyWith(animated: animated, animations: animations);
  }
}

// ============================================================================
// CONFIGURABLE BUILDER EXTENSION
// ============================================================================

/// Builder extension for [Configurable] widgets.
///
/// Provides the combined `configured` method for setting multiple
/// options at once, plus inherits all methods from `ThemeableBuilder`
/// and `AnimatableBuilder`.
///
/// **Example:**
/// ```dart
/// // Set theme and animations in one call
/// final prompt = MyPrompt('Label')
///   .configured(theme: PromptTheme.matrix, animated: true);
///
/// // Or chain individual methods
/// final prompt = MyPrompt('Label')
///   .withMatrixTheme()
///   .withSmoothAnimations();
/// ```
extension ConfigurableBuilder<T extends Configurable> on T {
  /// Creates a copy with multiple settings at once.
  ///
  /// More efficient than chaining multiple builder calls when
  /// you need to set both theme and animation options.
  ///
  /// ```dart
  /// // Instead of:
  /// prompt.withTheme(theme).withAnimations(anims)
  ///
  /// // Use:
  /// prompt.configured(theme: theme, animated: true, animations: anims)
  /// ```
  T configured({
    PromptTheme? theme,
    bool? animated,
    PromptAnimations? animations,
  }) {
    return copyWith(
      theme: theme,
      animated: animated,
      animations: animations,
    ) as T;
  }

  /// Creates a copy with a specific theme preset and animation preset.
  ///
  /// Convenience method for the common pattern of setting both at once.
  ///
  /// [themePreset] - One of: 'dark', 'matrix', 'fire', 'pastel'
  /// [animationPreset] - One of: 'none', 'quick', 'smooth', 'flashy'
  ///
  /// ```dart
  /// final prompt = MyPrompt('Label')
  ///   .withPresets(theme: 'matrix', animation: 'smooth');
  /// ```
  T withPresets({String? theme, String? animation}) {
    PromptTheme? themeValue;
    if (theme != null) {
      themeValue = _resolveThemePreset(theme);
    }

    PromptAnimations? animValue;
    bool? animatedValue;
    if (animation != null) {
      final resolved = _resolveAnimationPreset(animation);
      animValue = resolved.$1;
      animatedValue = resolved.$2;
    }

    return copyWith(
      theme: themeValue,
      animated: animatedValue,
      animations: animValue,
    ) as T;
  }

  /// Applies the "matrix" visual style: green theme + smooth animations.
  T withMatrixStyle() {
    return copyWith(
      theme: PromptTheme.matrix,
      animated: true,
      animations: PromptAnimations.smooth(),
    ) as T;
  }

  /// Applies the "fire" visual style: red theme + flashy animations.
  T withFireStyle() {
    return copyWith(
      theme: PromptTheme.fire,
      animated: true,
      animations: PromptAnimations.flashy(),
    ) as T;
  }

  /// Applies the "pastel" visual style: soft theme + quick animations.
  T withPastelStyle() {
    return copyWith(
      theme: PromptTheme.pastel,
      animated: true,
      animations: PromptAnimations.quick(),
    ) as T;
  }

  /// Applies minimal style: dark theme + no animations.
  T withMinimalStyle() {
    return copyWith(
      theme: PromptTheme.dark,
      animated: false,
      animations: PromptAnimations.none,
    ) as T;
  }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

PromptTheme _resolveThemePreset(String name) {
  switch (name.toLowerCase()) {
    case 'dark':
      return PromptTheme.dark;
    case 'matrix':
      return PromptTheme.matrix;
    case 'fire':
      return PromptTheme.fire;
    case 'pastel':
      return PromptTheme.pastel;
    default:
      return PromptTheme.dark;
  }
}

(PromptAnimations?, bool?) _resolveAnimationPreset(String name) {
  switch (name.toLowerCase()) {
    case 'none':
      return (PromptAnimations.none, false);
    case 'quick':
      return (PromptAnimations.quick(), true);
    case 'smooth':
      return (PromptAnimations.smooth(), true);
    case 'flashy':
      return (PromptAnimations.flashy(), true);
    default:
      return (null, null);
  }
}

