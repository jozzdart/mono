import '../style/theme.dart';
import '../system/key_events.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/line_builder.dart';
import '../system/prompt_runner.dart';
import '../system/text_input_buffer.dart';

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

  Future<String?> run() async {
    final style = theme.style;
    // Use centralized text input for buffer handling
    final buffer = TextInputBuffer();
    bool confirmed = false;
    bool valid = true;
    String? error;
    final cursorBlink = CursorBlink();

    void render(RenderOutput out) {
      // Use centralized line builder for consistent styling
      final lb = LineBuilder(theme);

      // Title
      final frame = FramedLayout(prompt, theme: theme);
      final baseTitle = frame.top();
      final title = style.boldPrompt
          ? '${theme.bold}$baseTitle${theme.reset}'
          : baseTitle;
      out.writeln(title);

      // Input line
      final text = buffer.isEmpty
          ? '${theme.dim}${placeholder ?? ''}${theme.reset}'
          : buffer.text;
      final cursor =
          cursorBlink.isVisible ? '${theme.accent}▌${theme.reset}' : ' ';
      final validatedColor = valid ? theme.accent : theme.checkboxOn;

      out.writeln('${lb.gutter()}$validatedColor$text$cursor${theme.reset}');

      // Error line (if invalid)
      if (error != null) {
        out.writeln('${lb.gutter()}${theme.highlight}$error${theme.reset}');
      } else {
        out.writeln('${lb.gutter()}${Hints.comma([
              'Enter to confirm',
              'Esc to cancel'
            ], theme)}');
      }

      // Bottom border
      if (style.showBorder) {
        out.writeln(frame.bottom());
      }
    }

    final runner = PromptRunner(hideCursor: true);
    await runner.runAsync(
      render: render,
      cursorBlink: cursorBlink,
      onKey: (event) {
        // ENTER → Validate & exit if valid
        if (event.type == KeyEventType.enter) {
          final text = buffer.text.trim();
          if (required && text.isEmpty) {
            valid = false;
            error = 'Input cannot be empty.';
          } else if (validator != null) {
            final result = validator!(text);
            if (result.isNotEmpty) {
              valid = false;
              error = result;
            } else {
              valid = true;
              error = null;
            }
          } else {
            valid = true;
            error = null;
          }

          if (valid) {
            confirmed = true;
            return PromptResult.confirmed;
          }
        }

        // ESC → Cancel
        else if (event.type == KeyEventType.esc) {
          return PromptResult.cancelled;
        }

        // Text input (typing, backspace) - handled by centralized TextInputBuffer
        else if (buffer.handleKey(event)) {
          // Input was modified
        }

        valid = true;
        error = null;
        return null; // continue loop
      },
    );

    return confirmed ? buffer.text.trim() : null;
  }
}
