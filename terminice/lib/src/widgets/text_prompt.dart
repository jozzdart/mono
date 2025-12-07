import '../style/prompt_config.dart';
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
/// **Configuration:** Supports both direct theme and [PromptConfig]:
/// ```dart
/// // Fluent API
/// final name = await TextPrompt(prompt: 'Name')
///   .withPastelTheme()
///   .run();
///
/// // With shared config
/// final config = PromptConfig.matrix;
/// final name = await TextPrompt(prompt: 'Name', config: config).run();
/// ```
class TextPrompt with Themeable {
  final String prompt;
  final String? placeholder;
  @override
  final PromptTheme theme;
  final String Function(String)? validator;
  final bool required;

  /// Creates a text input prompt.
  ///
  /// Accepts either:
  /// - A [PromptConfig] object (theme extracted automatically)
  /// - A direct [theme] parameter (for convenience)
  TextPrompt({
    required this.prompt,
    this.placeholder,
    this.validator,
    this.required = true,
    // Config object (preferred for shared configuration)
    PromptConfig? config,
    // Direct theme (for convenience)
    PromptTheme theme = PromptTheme.dark,
  }) : theme = config?.theme ?? theme;

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
