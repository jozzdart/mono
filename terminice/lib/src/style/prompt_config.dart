import '../system/prompt_animations.dart';
import 'theme.dart';

// ============================================================================
// PROMPT CONFIG – Reusable configuration object for prompts
// ============================================================================

/// `PromptConfig` – Composable configuration for prompts.
///
/// A reusable configuration object that encapsulates theme and animation settings.
/// Can be passed around, stored, and reused across multiple prompts.
///
/// **Problem it solves:**
///
/// Instead of passing multiple parameters to every prompt:
/// ```dart
/// // OLD: Multiple parameters to pass around
/// SliderPrompt('Volume', theme: theme, animated: true, animations: anims);
/// RatingPrompt('Rate', theme: theme, animated: true, animations: anims);
/// ```
///
/// **Use a single config:**
/// ```dart
/// // NEW: Single config object, reusable
/// final config = PromptConfig.matrixAnimated();
/// SliderPrompt('Volume', config: config);
/// RatingPrompt('Rate', config: config);
/// ```
///
/// **Design principles:**
/// - **Composition over inheritance**: Config is composed into widgets
/// - **Separation of concerns**: Config handles styling, widget handles logic
/// - **DRY**: Create once, reuse everywhere
/// - **Open/closed**: Easy to extend config without modifying widgets
///
/// **Usage:**
/// ```dart
/// // Create with defaults
/// final config = PromptConfig();
///
/// // Create with custom settings
/// final config = PromptConfig(
///   theme: PromptTheme.matrix,
///   animated: true,
///   animations: PromptAnimations.smooth(),
/// );
///
/// // Builder pattern (fluent API)
/// final config = PromptConfig()
///   .withMatrixTheme()
///   .withSmoothAnimations();
///
/// // Use in widgets
/// SliderPrompt('Volume', config: config).run();
/// ```
class PromptConfig {
  /// The theme for styling.
  final PromptTheme theme;

  /// Whether animations are enabled by default.
  final bool animated;

  /// Custom animation configuration (overrides [animated]).
  final PromptAnimations? animations;

  /// Creates a prompt configuration.
  ///
  /// [theme] defaults to [PromptTheme.dark].
  /// [animated] defaults to false for backwards compatibility.
  /// [animations] can be set for custom animation configuration.
  const PromptConfig({
    this.theme = PromptTheme.dark,
    this.animated = false,
    this.animations,
  });

  // ──────────────────────────────────────────────────────────────────────────
  // FACTORY PRESETS
  // ──────────────────────────────────────────────────────────────────────────

  /// Default configuration (dark theme, no animations).
  static const PromptConfig defaults = PromptConfig();

  /// Dark theme with smooth animations.
  static PromptConfig darkAnimated() => const PromptConfig(
        theme: PromptTheme.dark,
        animated: true,
      );

  /// Matrix theme (green, terminal-style).
  static const PromptConfig matrix = PromptConfig(theme: PromptTheme.matrix);

  /// Matrix theme with smooth animations.
  static PromptConfig matrixAnimated() => const PromptConfig(
        theme: PromptTheme.matrix,
        animated: true,
      );

  /// Fire theme (red/orange, bold).
  static const PromptConfig fire = PromptConfig(theme: PromptTheme.fire);

  /// Pastel theme (soft, gentle colors).
  static const PromptConfig pastel = PromptConfig(theme: PromptTheme.pastel);

  /// Ocean theme (calming blue/cyan tones).
  static const PromptConfig ocean = PromptConfig(theme: PromptTheme.ocean);

  /// Ocean theme with smooth animations.
  static PromptConfig oceanAnimated() => const PromptConfig(
        theme: PromptTheme.ocean,
        animated: true,
      );

  /// Monochrome theme (high-contrast ASCII retro).
  static const PromptConfig monochrome =
      PromptConfig(theme: PromptTheme.monochrome);

  /// Neon theme (vibrant synthwave cyberpunk).
  static const PromptConfig neon = PromptConfig(theme: PromptTheme.neon);

  /// Neon theme with flashy animations.
  static PromptConfig neonAnimated() => const PromptConfig(
        theme: PromptTheme.neon,
        animated: true,
      );

  /// Arcane theme (mystical ancient tome aesthetic).
  static const PromptConfig arcane = PromptConfig(theme: PromptTheme.arcane);

  /// Arcane theme with smooth mystical animations.
  static PromptConfig arcaneAnimated() => const PromptConfig(
        theme: PromptTheme.arcane,
        animated: true,
      );

  /// Phantom theme (ghostly apparition aesthetic).
  static const PromptConfig phantom = PromptConfig(theme: PromptTheme.phantom);

  /// Phantom theme with smooth ethereal animations.
  static PromptConfig phantomAnimated() => const PromptConfig(
        theme: PromptTheme.phantom,
        animated: true,
      );

  // ──────────────────────────────────────────────────────────────────────────
  // COPY WITH METHODS
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates a copy with modified settings.
  PromptConfig copyWith({
    PromptTheme? theme,
    bool? animated,
    PromptAnimations? animations,
  }) {
    return PromptConfig(
      theme: theme ?? this.theme,
      animated: animated ?? this.animated,
      animations: animations ?? this.animations,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // THEME BUILDER METHODS
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates a copy with a custom theme.
  PromptConfig withTheme(PromptTheme theme) => copyWith(theme: theme);

  /// Creates a copy with the dark theme (default).
  PromptConfig withDarkTheme() => withTheme(PromptTheme.dark);

  /// Creates a copy with the matrix theme (green, terminal-style).
  PromptConfig withMatrixTheme() => withTheme(PromptTheme.matrix);

  /// Creates a copy with the fire theme (red/orange, bold).
  PromptConfig withFireTheme() => withTheme(PromptTheme.fire);

  /// Creates a copy with the pastel theme (soft, gentle colors).
  PromptConfig withPastelTheme() => withTheme(PromptTheme.pastel);

  /// Creates a copy with the ocean theme (calming blue/cyan).
  PromptConfig withOceanTheme() => withTheme(PromptTheme.ocean);

  /// Creates a copy with the monochrome theme (high-contrast ASCII).
  PromptConfig withMonochromeTheme() => withTheme(PromptTheme.monochrome);

  /// Creates a copy with the neon theme (vibrant synthwave).
  PromptConfig withNeonTheme() => withTheme(PromptTheme.neon);

  /// Creates a copy with the arcane theme (mystical ancient tome).
  PromptConfig withArcaneTheme() => withTheme(PromptTheme.arcane);

  /// Creates a copy with the phantom theme (ghostly apparition).
  PromptConfig withPhantomTheme() => withTheme(PromptTheme.phantom);

  // ──────────────────────────────────────────────────────────────────────────
  // ANIMATION BUILDER METHODS
  // ──────────────────────────────────────────────────────────────────────────

  /// Creates a copy with animations enabled.
  ///
  /// If [animations] is provided, uses that configuration.
  /// Otherwise, uses the default animation preset.
  PromptConfig withAnimations([PromptAnimations? animations]) {
    return copyWith(animated: true, animations: animations);
  }

  /// Creates a copy with animations disabled.
  PromptConfig withoutAnimations() {
    return copyWith(animated: false, animations: PromptAnimations.none);
  }

  /// Creates a copy with quick, responsive animations.
  ///
  /// Best for: Short interactions, confirmations, rapid feedback.
  PromptConfig withQuickAnimations() {
    return copyWith(animated: true, animations: PromptAnimations.quick());
  }

  /// Creates a copy with smooth, polished animations.
  ///
  /// Best for: Sliders, ranges, value selection with visual feedback.
  PromptConfig withSmoothAnimations() {
    return copyWith(animated: true, animations: PromptAnimations.smooth());
  }

  /// Creates a copy with flashy, attention-grabbing animations.
  ///
  /// Best for: Important selections, celebrations, emphasis.
  PromptConfig withFlashyAnimations() {
    return copyWith(animated: true, animations: PromptAnimations.flashy());
  }

  /// Creates a copy with fully custom animation configuration.
  PromptConfig withCustomAnimations(PromptAnimations animations) {
    return copyWith(animated: true, animations: animations);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STYLE PRESETS (theme + animation combos)
  // ──────────────────────────────────────────────────────────────────────────

  /// Matrix visual style: green theme + smooth animations.
  PromptConfig withMatrixStyle() {
    return copyWith(
      theme: PromptTheme.matrix,
      animated: true,
      animations: PromptAnimations.smooth(),
    );
  }

  /// Fire visual style: red theme + flashy animations.
  PromptConfig withFireStyle() {
    return copyWith(
      theme: PromptTheme.fire,
      animated: true,
      animations: PromptAnimations.flashy(),
    );
  }

  /// Pastel visual style: soft theme + quick animations.
  PromptConfig withPastelStyle() {
    return copyWith(
      theme: PromptTheme.pastel,
      animated: true,
      animations: PromptAnimations.quick(),
    );
  }

  /// Minimal style: dark theme + no animations.
  PromptConfig withMinimalStyle() {
    return copyWith(
      theme: PromptTheme.dark,
      animated: false,
      animations: PromptAnimations.none,
    );
  }

  /// Ocean visual style: blue theme + smooth animations.
  PromptConfig withOceanStyle() {
    return copyWith(
      theme: PromptTheme.ocean,
      animated: true,
      animations: PromptAnimations.smooth(),
    );
  }

  /// Monochrome visual style: ASCII theme + no animations.
  PromptConfig withMonochromeStyle() {
    return copyWith(
      theme: PromptTheme.monochrome,
      animated: false,
      animations: PromptAnimations.none,
    );
  }

  /// Neon visual style: synthwave theme + flashy animations.
  PromptConfig withNeonStyle() {
    return copyWith(
      theme: PromptTheme.neon,
      animated: true,
      animations: PromptAnimations.flashy(),
    );
  }

  /// Arcane visual style: mystical theme + smooth enchanting animations.
  PromptConfig withArcaneStyle() {
    return copyWith(
      theme: PromptTheme.arcane,
      animated: true,
      animations: PromptAnimations.smooth(),
    );
  }

  /// Phantom visual style: ghostly theme + smooth ethereal animations.
  PromptConfig withPhantomStyle() {
    return copyWith(
      theme: PromptTheme.phantom,
      animated: true,
      animations: PromptAnimations.smooth(),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ANIMATION RESOLUTION
  // ──────────────────────────────────────────────────────────────────────────

  /// Resolves the effective animation configuration.
  ///
  /// Returns [animations] if set, otherwise returns the appropriate preset
  /// based on [animated] flag.
  ///
  /// [defaultAnimated] - The preset to use when [animated] is true but
  /// [animations] is null. Defaults to [PromptAnimations.smooth].
  PromptAnimations resolveAnimations([
    PromptAnimations Function()? defaultAnimated,
  ]) {
    if (animations != null) return animations!;
    if (!animated) return PromptAnimations.none;
    return (defaultAnimated ?? PromptAnimations.smooth)();
  }

  /// Whether any animation is effectively enabled.
  bool get hasAnimations {
    final resolved = resolveAnimations();
    return resolved.entry.enabled ||
        resolved.exit.enabled ||
        resolved.pulse.enabled;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PromptConfig &&
        other.theme == theme &&
        other.animated == animated &&
        other.animations == animations;
  }

  @override
  int get hashCode => Object.hash(theme, animated, animations);
}
