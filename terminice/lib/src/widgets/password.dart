import '../style/theme.dart';
import '../system/key_events.dart';
import '../system/hints.dart';
import '../system/framed_layout.dart';
import '../system/line_builder.dart';
import '../system/prompt_runner.dart';
import '../system/text_input_buffer.dart';

/// PasswordPrompt – secure masked input with toggle visibility (Ctrl+R)
class PasswordPrompt {
  final String label;
  final PromptTheme theme;
  final bool allowEmpty;
  final String maskChar;

  PasswordPrompt({
    required this.label,
    this.theme = PromptTheme.dark,
    this.allowEmpty = false,
    this.maskChar = '•',
  });

  String run() {
    final style = theme.style;
    // Use centralized text input for buffer handling
    final buffer = TextInputBuffer();
    bool showPlain = false;
    bool confirmed = false;
    final cursorBlink = CursorBlink();

    void render(RenderOutput out) {
      // Use centralized line builder for consistent styling
      final lb = LineBuilder(theme);

      // Top border
      final frame = FramedLayout(label, theme: theme);
      final topLine = frame.top();
      if (style.boldPrompt) {
        out.writeln('${theme.bold}$topLine${theme.reset}');
      } else {
        out.writeln(topLine);
      }

      // Input display
      final display = showPlain ? buffer.text : maskChar * buffer.length;
      final cursor =
          cursorBlink.isVisible ? '${theme.accent}▋${theme.reset}' : ' ';
      final content = buffer.isEmpty
          ? lb.emptyMessage('empty')
          : '$display$cursor';

      out.writeln('${lb.gutter()}${lb.arrowAccent()} $content');

      // Bottom line
      if (style.showBorder) {
        out.writeln(frame.bottom());
      }

      // Hints
      final hints = <String>[
        Hints.hint('Ctrl+R', 'reveal', theme),
        Hints.hint('Enter', 'confirm', theme),
        Hints.hint('Esc', 'cancel', theme),
      ];
      out.writeln(Hints.bullets(hints, theme));
    }

    final runner = PromptRunner(hideCursor: true);
    runner.runAsync(
      render: render,
      cursorBlink: cursorBlink,
      onKey: (event) {
        if (event.type == KeyEventType.enter) {
          if (allowEmpty || buffer.isNotEmpty) {
            confirmed = true;
            return PromptResult.confirmed;
          }
        } else if (event.type == KeyEventType.ctrlC ||
            event.type == KeyEventType.esc) {
          return PromptResult.cancelled;
        } else if (event.type == KeyEventType.ctrlR) {
          showPlain = !showPlain;
        } else {
          // Text input (typing, backspace) - handled by centralized TextInputBuffer
          buffer.handleKey(event);
        }

        return null; // continue loop
      },
    );

    if (!confirmed) return '';
    return buffer.text;
  }
}
