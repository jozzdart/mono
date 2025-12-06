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
///
/// **Mixins:** Implements [Themeable] for fluent theme configuration:
/// ```dart
/// final name = await TextPrompt(prompt: 'Name')
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

  TextPrompt({
    required this.prompt,
    this.placeholder,
    this.theme = PromptTheme.dark,
    this.validator,
    this.required = true,
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
