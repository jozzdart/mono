import '../style/theme.dart';
import '../system/simple_prompt.dart';

/// A text input prompt with blinking cursor, placeholder, and validation.
///
/// Features:
/// - Animated cursor (blinking)
/// - Theme-aware styling
/// - Placeholder text
/// - Live validation feedback
/// - Optional required input
///
/// Controls:
/// - Type to enter text
/// - Backspace to delete
/// - Enter to confirm
/// - Esc to cancel
///
/// **Implementation:** Uses [AsyncTextPrompt] for core functionality,
/// demonstrating composition over inheritance.
class TextPrompt {
  final String prompt;
  final String? placeholder;
  final PromptTheme theme;
  final String Function(String)? validator;
  final bool required;

  TextPrompt({
    required this.prompt,
    this.placeholder,
    this.theme = PromptTheme.dark,
    this.validator,
    this.required = true,
  });

  /// Runs the prompt and returns the entered text.
  ///
  /// Returns null if cancelled or validation fails.
  Future<String?> run() async {
    return AsyncTextPrompt(
      title: prompt,
      theme: theme,
      placeholder: placeholder,
      validator: validator,
      required: required,
    ).run();
  }
}
