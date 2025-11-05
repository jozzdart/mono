import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import '../style/theme.dart';
import '../system/terminal.dart';
import '../system/key_events.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';

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
    final buffer = StringBuffer();
    bool cancelled = false;
    bool showCursor = true;
    bool valid = true;
    String? error;

    // Terminal setup
    final term = Terminal.enterRaw();
    Terminal.hideCursor(); // hide real cursor

    void cleanup() {
      term.restore();
      stdout.write('\x1B[?25h'); // show cursor again
    }

    void render() {
      Terminal.clearAndHome();

      // Title
      final frame = FramedLayout(prompt, theme: theme);
      final baseTitle = frame.top();
      final title = style.boldPrompt
          ? '${theme.bold}$baseTitle${theme.reset}'
          : baseTitle;
      stdout.writeln(title);

      // Input line
      final text = buffer.isEmpty
          ? '${theme.dim}${placeholder ?? ''}${theme.reset}'
          : buffer.toString();
      final cursor = showCursor ? '${theme.accent}▌${theme.reset}' : ' ';
      final validatedColor = valid ? theme.accent : theme.checkboxOn;

      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} $validatedColor$text$cursor${theme.reset}');

      // Error line (if invalid)
      if (error != null) {
        stdout.writeln(
            '${theme.gray}${style.borderVertical}${theme.reset} ${theme.highlight}$error${theme.reset}');
      } else {
        stdout.writeln(
            '${theme.gray}${style.borderVertical}${theme.reset} ${Hints.comma([
              'Enter to confirm',
              'Esc to cancel'
            ], theme)}');
      }

      // Bottom border
      if (style.showBorder) {
        stdout.writeln(frame.bottom());
      }
    }

    final cursorTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) {
        showCursor = !showCursor;
        render();
      },
    );

    render();

    try {
      while (true) {
        final ev = KeyEventReader.read();

        // ENTER → Validate & exit if valid
        if (ev.type == KeyEventType.enter) {
          final text = buffer.toString().trim();
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

          if (valid) break;
        }

        // ESC → Cancel
        else if (ev.type == KeyEventType.esc) {
          cancelled = true;
          break;
        }

        // BACKSPACE
        else if (ev.type == KeyEventType.backspace) {
          if (buffer.isNotEmpty) {
            buffer.clear();
            final text = buffer.toString();
            buffer.write(text.substring(0, math.max(0, text.length - 1)));
          }
        }

        // Regular character
        else if (ev.type == KeyEventType.char && ev.char != null) {
          buffer.write(ev.char!);
        }

        valid = true;
        error = null;
        render();
      }
    } finally {
      cursorTimer.cancel();
      cleanup();
    }

    Terminal.clearAndHome();
    Terminal.showCursor();
    return cancelled ? null : buffer.toString().trim();
  }
}
