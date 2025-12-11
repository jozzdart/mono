import 'package:terminice/terminice.dart';

/// Password input prompt with masking and optional reveal.
///
/// Controls:
/// - Type to enter password
/// - Backspace to delete
/// - Ctrl+R to reveal/hide
/// - Enter to confirm
/// - Esc to cancel
///
/// **Example:**
/// ```dart
/// final password = PasswordPrompt(prompt: 'Password')
///   .withMatrixTheme()
///   .run();
/// ```
class PasswordPrompt with Themeable {
  final String prompt;
  @override
  final PromptTheme theme;
  final bool required;
  final bool allowReveal;
  final String maskChar;

  /// Creates a password input prompt.
  PasswordPrompt({
    required this.prompt,
    this.required = true,
    this.allowReveal = true,
    this.maskChar = '•',
    this.theme = PromptTheme.dark,
  });

  @override
  PasswordPrompt copyWithTheme(PromptTheme theme) {
    return PasswordPrompt(
      prompt: prompt,
      theme: theme,
      required: required,
      allowReveal: allowReveal,
      maskChar: maskChar,
    );
  }

  /// Runs the prompt and returns the entered password.
  ///
  /// Returns null if cancelled.
  String? run() {
    return TextPromptSync(
      title: prompt,
      theme: theme,
      required: required,
      masked: true,
      maskChar: maskChar,
      allowReveal: allowReveal,
    ).run();
  }
}

extension PasswordPromptExtensions on Terminice {
  /// Password input prompt with masked characters.
  ///
  /// Returns the entered password, or empty string if cancelled.
  ///
  /// **Example:**
  /// ```dart
  /// final pwd = terminice.password(label: 'Password');
  /// final secret = terminice.arcane.password(label: 'Secret');
  /// ```
  String? password({
    required String prompt,
    bool required = true,
    String maskChar = '•',
    bool allowReveal = true,
    PromptTheme? theme,
  }) {
    return PasswordPrompt(
      prompt: prompt,
      required: required,
      maskChar: maskChar,
      allowReveal: allowReveal,
      theme: theme ?? defaultTheme,
    ).run();
  }
}
