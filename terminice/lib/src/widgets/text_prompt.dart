import '../style/theme.dart';
import '../system/hints.dart';
import '../system/key_bindings.dart';
import '../system/prompt_runner.dart';
import '../system/text_input_buffer.dart';
import '../system/widget_frame.dart';

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
    // Use centralized text input for buffer handling
    final buffer = TextInputBuffer();
    bool confirmed = false;
    bool valid = true;
    String? error;
    final cursorBlink = CursorBlink();

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings.textInput(buffer: buffer) +
        KeyBindings.confirm(onConfirm: () {
          // Validate on confirm
          final text = buffer.text.trim();
          if (required && text.isEmpty) {
            valid = false;
            error = 'Input cannot be empty.';
            return KeyActionResult.handled;
          } else if (validator != null) {
            final result = validator!(text);
            if (result.isNotEmpty) {
              valid = false;
              error = result;
              return KeyActionResult.handled;
            }
          }
          valid = true;
          error = null;
          confirmed = true;
          return KeyActionResult.confirmed;
        }) +
        KeyBindings.cancel();

    // Use WidgetFrame for consistent frame rendering
    final frame = WidgetFrame(
      title: prompt,
      theme: theme,
      bindings: null, // We handle hints manually for this widget
    );

    void render(RenderOutput out) {
      frame.renderContent(out, (ctx) {
        // Input line
        final text = buffer.isEmpty
            ? '${theme.dim}${placeholder ?? ''}${theme.reset}'
            : buffer.text;
        final cursor =
            cursorBlink.isVisible ? '${theme.accent}▌${theme.reset}' : ' ';
        final validatedColor = valid ? theme.accent : theme.checkboxOn;

        ctx.gutterLine('$validatedColor$text$cursor${theme.reset}');

        // Error line (if invalid) or hints
        if (error != null) {
          ctx.gutterLine('${theme.highlight}$error${theme.reset}');
        } else {
          ctx.gutterLine(
              Hints.comma(['Enter to confirm', 'Esc to cancel'], theme));
        }
      });
    }

    final runner = PromptRunner(hideCursor: true);
    await runner.runAsyncWithBindings(
      render: render,
      cursorBlink: cursorBlink,
      bindings: bindings.add(KeyBinding(
        // Reset validation state on any text input
        keys: {KeyEventType.char, KeyEventType.backspace},
        action: (_) {
          valid = true;
          error = null;
          return KeyActionResult.ignored; // Let the textInput binding handle it
        },
      )),
    );

    return confirmed ? buffer.text.trim() : null;
  }
}
