import '../style/prompt_config.dart';
import '../style/theme.dart';
import '../system/simple_prompt.dart';

/// PasswordPrompt – secure masked input with toggle visibility (Ctrl+R)
///
/// Controls:
/// - Type to enter text
/// - Backspace to delete
/// - Enter to confirm
/// - Esc to cancel
/// - Ctrl+R to toggle visibility
///
/// **Implementation:** Uses [AsyncSimplePrompts.password] for core functionality,
/// demonstrating composition over inheritance.
///
/// **Configuration:** Supports both direct theme and [PromptConfig]:
/// ```dart
/// // Fluent API
/// final password = await PasswordPrompt(label: 'Password')
///   .withMatrixTheme()
///   .run();
///
/// // With shared config
/// final config = PromptConfig.matrix;
/// final password = await PasswordPrompt(label: 'Password', config: config).run();
/// ```
class PasswordPrompt with Themeable {
  final String label;
  @override
  final PromptTheme theme;
  final bool allowEmpty;
  final String maskChar;

  /// Creates a password input prompt.
  ///
  /// Accepts either:
  /// - A [PromptConfig] object (theme extracted automatically)
  /// - A direct [theme] parameter (for convenience)
  PasswordPrompt({
    required this.label,
    this.allowEmpty = false,
    this.maskChar = '•',
    // Config object (preferred for shared configuration)
    PromptConfig? config,
    // Direct theme (for convenience)
    PromptTheme theme = PromptTheme.dark,
  }) : theme = config?.theme ?? theme;

  @override
  PasswordPrompt copyWithTheme(PromptTheme theme) {
    return PasswordPrompt(
      label: label,
      theme: theme,
      allowEmpty: allowEmpty,
      maskChar: maskChar,
    );
  }

  /// Runs the prompt and returns the entered password.
  ///
  /// Returns empty string if cancelled or validation fails.
  Future<String> run() async {
    final result = await AsyncSimplePrompts.password(
      title: label,
      theme: theme,
      required: !allowEmpty,
      maskChar: maskChar,
      allowReveal: true,
    ).run();

    return result ?? '';
  }
}
