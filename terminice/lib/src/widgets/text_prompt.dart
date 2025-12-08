import 'package:terminice/terminice.dart';

/// A text input prompt with static cursor, placeholder, and validation.
///
/// Controls:
/// - Type to enter text
/// - Backspace to delete
/// - Enter to confirm
/// - Esc to cancel
///
/// **Example:**
/// ```dart
/// final name = TextPrompt(prompt: 'Name')
///   .withPastelTheme()
///   .run();
/// ```
class TextPrompt with Themeable {
  final String prompt;
  final String? placeholder;
  @override
  final PromptTheme theme;
  final String Function(String)? validator;
  final bool required;

  /// Creates a text input prompt.
  TextPrompt({
    required this.prompt,
    this.placeholder,
    this.validator,
    this.required = true,
    this.theme = PromptTheme.dark,
  });

  @override
  TextPrompt copyWithTheme(PromptTheme theme) {
    return TextPrompt(
      prompt: prompt,
      placeholder: placeholder,
      theme: theme,
      validator: validator,
      required: required,
    );
  }

  /// Runs the prompt and returns the entered text.
  ///
  /// Returns null if cancelled or validation fails.
  String? run() {
    return TextPromptSync(
      title: prompt,
      theme: theme,
      placeholder: placeholder,
      validator: validator,
      required: required,
    ).run();
  }
}
