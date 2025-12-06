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
/// **Why use this pattern?**
/// - **DRY**: Define theme property once, get all builder methods free
/// - **Consistency**: All themeable widgets have the same fluent API
/// - **Discoverability**: IDE autocomplete shows available themes
/// - **Type-safe**: Builder methods return the correct concrete type
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
  ///
  /// Implementers should copy all fields and apply the new theme.
  Themeable copyWithTheme(PromptTheme theme);
}

/// Builder extensions for [Themeable] widgets.
///
/// Provides a fluent API for configuring themes on any widget
/// that implements [Themeable]. All methods return the same concrete
/// type as the receiver, enabling type-safe chaining.
///
/// **Available methods:**
/// - [withTheme] - Apply any custom theme
/// - [withDarkTheme] - Apply the dark theme (default)
/// - [withMatrixTheme] - Apply the matrix/green theme
/// - [withFireTheme] - Apply the fire/red theme
/// - [withPastelTheme] - Apply the pastel/soft theme
///
/// **Example:**
/// ```dart
/// final prompt = SliderPrompt('Volume')
///   .withMatrixTheme()
///   .withSmoothAnimations()
///   .run();
/// ```
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
}
