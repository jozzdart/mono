/// Defines a complete styling system for the terminal prompt:
/// - Colors
/// - Box drawing characters
/// - Symbols and shapes
/// - Layout options
class PromptTheme {
  final PromptStyle style;
  final String reset;
  final String bold;
  final String dim;
  final String gray;
  final String accent;
  final String keyAccent;
  final String highlight;
  final String selection;
  final String checkboxOn;
  final String checkboxOff;
  final String inverse;
  final String info; // info/status color
  final String warn; // warning color
  final String error; // error color

  const PromptTheme({
    this.style = const PromptStyle(),
    this.reset = '\x1B[0m',
    this.bold = '\x1B[1m',
    this.dim = '\x1B[2m',
    this.gray = '\x1B[90m',
    this.accent = '\x1B[36m',
    this.keyAccent = '\x1B[37m',
    this.highlight = '\x1B[33m',
    this.selection = '\x1B[35m',
    this.checkboxOn = '\x1B[32m',
    this.checkboxOff = '\x1B[90m',
    this.inverse = '\x1B[7m',
    this.info = '\x1B[36m', // cyan by default
    this.warn = '\x1B[33m', // yellow by default
    this.error = '\x1B[31m', // red by default
  });

  /// Predefined themes
  static const PromptTheme dark = PromptTheme();

  static const PromptTheme matrix = PromptTheme(
    accent: '\x1B[32m',
    highlight: '\x1B[92m',
    selection: '\x1B[32m',
    checkboxOn: '\x1B[32m',
    checkboxOff: '\x1B[90m',
    info: '\x1B[32m', // green info
    warn: '\x1B[93m', // bright yellow warning
    error: '\x1B[31m', // red error
    style: PromptStyle(
      borderTop: '╭',
      borderBottom: '╰',
      borderVertical: '│',
      borderConnector: '├',
      arrow: '❯',
      checkboxOnSymbol: '◉',
      checkboxOffSymbol: '○',
    ),
  );

  static const PromptTheme fire = PromptTheme(
    accent: '\x1B[31m',
    highlight: '\x1B[33m',
    selection: '\x1B[31m',
    checkboxOn: '\x1B[31m',
    checkboxOff: '\x1B[90m',
    info: '\x1B[36m', // cyan info for readability
    warn: '\x1B[33m', // yellow warning
    error: '\x1B[31m', // red error
    style: PromptStyle(
      borderTop: '╔',
      borderBottom: '╚',
      borderVertical: '║',
      borderConnector: '╟',
      arrow: '➤',
      checkboxOnSymbol: '■',
      checkboxOffSymbol: '□',
    ),
  );

  static const PromptTheme pastel = PromptTheme(
    accent: '\x1B[95m',
    highlight: '\x1B[93m',
    selection: '\x1B[94m',
    checkboxOn: '\x1B[96m',
    checkboxOff: '\x1B[90m',
    info: '\x1B[96m', // pastel cyan
    warn: '\x1B[93m', // pastel yellow
    error: '\x1B[91m', // light red
    style: PromptStyle(
      borderTop: '┌',
      borderBottom: '└',
      borderVertical: '│',
      borderConnector: '├',
      arrow: '›',
      checkboxOnSymbol: '◆',
      checkboxOffSymbol: '◇',
    ),
  );

  /// Ocean theme – Calming deep blue and cyan tones like ocean depths.
  ///
  /// Best for: Long sessions, reading-heavy tasks, calm environments.
  static const PromptTheme ocean = PromptTheme(
    accent: '\x1B[94m', // bright blue
    highlight: '\x1B[96m', // bright cyan
    selection: '\x1B[34m', // blue
    keyAccent: '\x1B[36m', // cyan
    checkboxOn: '\x1B[94m', // bright blue
    checkboxOff: '\x1B[90m', // gray
    info: '\x1B[96m', // bright cyan
    warn: '\x1B[93m', // bright yellow
    error: '\x1B[91m', // bright red
    style: PromptStyle(
      borderTop: '╭',
      borderBottom: '╰',
      borderVertical: '┊',
      borderConnector: '├',
      arrow: '▸',
      checkboxOnSymbol: '●',
      checkboxOffSymbol: '○',
    ),
  );

  /// Monochrome theme – High-contrast ASCII retro terminal aesthetic.
  ///
  /// Best for: Classic terminal feel, high-visibility, minimal distraction.
  static const PromptTheme monochrome = PromptTheme(
    accent: '\x1B[97m', // bright white
    highlight: '\x1B[7m', // inverse for stark contrast
    selection: '\x1B[37m', // white
    keyAccent: '\x1B[97m', // bright white
    checkboxOn: '\x1B[97m', // bright white
    checkboxOff: '\x1B[90m', // gray
    info: '\x1B[37m', // white
    warn: '\x1B[97m', // bright white
    error: '\x1B[4m\x1B[97m', // underlined bright white
    style: PromptStyle(
      borderTop: '+',
      borderBottom: '+',
      borderVertical: '|',
      borderConnector: '+',
      arrow: '>',
      checkboxOnSymbol: '[x]',
      checkboxOffSymbol: '[ ]',
    ),
  );

  /// Neon theme – Vibrant synthwave cyberpunk with electric colors.
  ///
  /// Best for: Creative sessions, standout visuals, futuristic vibe.
  static const PromptTheme neon = PromptTheme(
    accent: '\x1B[95m', // bright magenta
    highlight: '\x1B[96m', // bright cyan
    selection: '\x1B[93m', // bright yellow
    keyAccent: '\x1B[95m', // bright magenta
    checkboxOn: '\x1B[96m', // bright cyan
    checkboxOff: '\x1B[90m', // gray
    info: '\x1B[95m', // bright magenta
    warn: '\x1B[93m', // bright yellow
    error: '\x1B[91m', // bright red
    style: PromptStyle(
      borderTop: '┏',
      borderBottom: '┗',
      borderVertical: '┃',
      borderConnector: '┣',
      arrow: '>',
      checkboxOnSymbol: '◈',
      checkboxOffSymbol: '◇',
    ),
  );

  /// Arcane theme – Mystical ancient tome aesthetic with magical runes.
  ///
  /// Uses 256-color palette for deep amethyst, ancient gold, and mystic hues.
  /// Unique glyph-like borders evoke spell scrolls and enchanted manuscripts.
  ///
  /// Best for: When you want magic in your terminal.
  static const PromptTheme arcane = PromptTheme(
    accent: '\x1B[38;5;141m', // soft amethyst violet
    highlight: '\x1B[38;5;220m', // ancient gold
    selection: '\x1B[38;5;99m', // deep mystic purple
    keyAccent: '\x1B[38;5;178m', // warm amber
    checkboxOn: '\x1B[38;5;220m', // gold (activated rune)
    checkboxOff: '\x1B[38;5;240m', // faded stone gray
    info: '\x1B[38;5;147m', // light lavender mist
    warn: '\x1B[38;5;214m', // burning orange
    error: '\x1B[38;5;160m', // blood crimson
    style: PromptStyle(
      borderTop: '⸢',
      borderBottom: '⸤',
      borderVertical: '⁞',
      borderConnector: '⊢',
      arrow: '⊳',
      checkboxOnSymbol: '⬢',
      checkboxOffSymbol: '⬡',
    ),
  );

  /// Phantom theme – Ghostly apparition materializing from shadow.
  ///
  /// Ethereal gray-violet tones with spectral glows. Half-brackets float
  /// like corners emerging from void. Broken bars suggest translucency.
  /// The presence/absence symbolized by watching eyes and empty circles.
  ///
  /// Best for: When you want to feel like a ghost in the machine.
  static const PromptTheme phantom = PromptTheme(
    accent: '\x1B[38;5;103m', // ghostly gray-violet
    highlight: '\x1B[38;5;255m', // sudden spectral flash
    selection: '\x1B[38;5;60m', // shadow purple
    keyAccent: '\x1B[38;5;146m', // faded lavender whisper
    checkboxOn: '\x1B[38;5;189m', // spectral presence glow
    checkboxOff: '\x1B[38;5;236m', // deep shadow absence
    info: '\x1B[38;5;103m', // ghostly murmur
    warn: '\x1B[38;5;180m', // eerie candlelight amber
    error: '\x1B[38;5;131m', // blood mist
    style: PromptStyle(
      borderTop: '⌜',
      borderBottom: '⌞',
      borderVertical: '¦',
      borderConnector: '·',
      arrow: '›',
      checkboxOnSymbol: '◉',
      checkboxOffSymbol: '◌',
    ),
  );
}

class PromptStyle {
  final String borderTop;
  final String borderBottom;
  final String borderVertical;
  final String borderConnector;
  final String arrow;
  final String checkboxOnSymbol;
  final String checkboxOffSymbol;
  final bool useInverseHighlight;
  final bool boldPrompt;
  final bool showBorder;

  const PromptStyle({
    this.borderTop = '┌',
    this.borderBottom = '└',
    this.borderVertical = '│',
    this.borderConnector = '├',
    this.arrow = '▶',
    this.checkboxOnSymbol = '■',
    this.checkboxOffSymbol = '□',
    this.useInverseHighlight = true,
    this.boldPrompt = true,
    this.showBorder = true,
  });
}

// ============================================================================
// THEMEABLE MIXIN – DRY builder pattern for theme-aware widgets
// ============================================================================

/// Mixin for widgets that support theme configuration.
///
/// Implementing this mixin provides automatic builder methods via the
/// [ThemeableBuilder] extension, eliminating repetitive copyWith patterns.
///
/// **Implementation:**
///
/// 1. Add `with Themeable` to your widget class
/// 2. Add `theme` field (usually with `PromptTheme.dark` default)
/// 3. Implement `copyWithTheme` to create a copy with a new theme
///
/// ```dart
/// class MyWidget with Themeable {
///   final String label;
///   @override
///   final PromptTheme theme;
///
///   MyWidget(this.label, {this.theme = PromptTheme.dark});
///
///   @override
///   MyWidget copyWithTheme(PromptTheme theme) {
///     return MyWidget(label, theme: theme);
///   }
/// }
///
/// // Now you get all these methods automatically:
/// final widget = MyWidget('Test')
///   .withTheme(PromptTheme.matrix)  // Custom theme
///   .withDarkTheme()                // Dark preset
///   .withMatrixTheme()              // Matrix preset
///   .withFireTheme()                // Fire preset
///   .withPastelTheme();             // Pastel preset
/// ```
mixin Themeable {
  /// The current theme for styling.
  PromptTheme get theme;

  /// Creates a copy with a different theme.
  Themeable copyWithTheme(PromptTheme theme);
}

/// Builder extensions for [Themeable] widgets.
extension ThemeableBuilder<T extends Themeable> on T {
  /// Creates a copy with a custom theme.
  T withTheme(PromptTheme theme) {
    return copyWithTheme(theme) as T;
  }

  /// Creates a copy with the dark theme (default).
  T withDarkTheme() => withTheme(PromptTheme.dark);

  /// Creates a copy with the matrix theme (green, terminal-style).
  T withMatrixTheme() => withTheme(PromptTheme.matrix);

  /// Creates a copy with the fire theme (red/orange, bold).
  T withFireTheme() => withTheme(PromptTheme.fire);

  /// Creates a copy with the pastel theme (soft, gentle colors).
  T withPastelTheme() => withTheme(PromptTheme.pastel);

  /// Creates a copy with the ocean theme (calming blue/cyan).
  T withOceanTheme() => withTheme(PromptTheme.ocean);

  /// Creates a copy with the monochrome theme (high-contrast ASCII).
  T withMonochromeTheme() => withTheme(PromptTheme.monochrome);

  /// Creates a copy with the neon theme (vibrant synthwave).
  T withNeonTheme() => withTheme(PromptTheme.neon);

  /// Creates a copy with the arcane theme (mystical ancient tome).
  T withArcaneTheme() => withTheme(PromptTheme.arcane);

  /// Creates a copy with the phantom theme (ghostly apparition).
  T withPhantomTheme() => withTheme(PromptTheme.phantom);
}

// ============================================================================
// SHARED STYLE ENUMS
// ============================================================================

/// Badge/label tones for consistent color theming across widgets.
///
/// Used by [Badge], [InlineStyle], [FrameContext] and other components
/// that need semantic color variants.
enum BadgeTone {
  /// Neutral/default (gray)
  neutral,

  /// Informational (accent color)
  info,

  /// Success/positive (green/checkbox-on color)
  success,

  /// Warning (highlight/yellow color)
  warning,

  /// Danger/error (red color)
  danger,
}
