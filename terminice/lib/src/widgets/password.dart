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
/// **Mixins:** Implements [Themeable] for fluent theme configuration:
/// ```dart
/// final password = await PasswordPrompt(label: 'Password')
///   .withMatrixTheme()
///   .run();
/// ```
class PasswordPrompt with Themeable {
  final String label;
  @override
  final PromptTheme theme;
  final bool allowEmpty;
  final String maskChar;

  PasswordPrompt({
    required this.label,
    this.theme = PromptTheme.dark,
    this.allowEmpty = false,
    this.maskChar = '•',
  });

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
