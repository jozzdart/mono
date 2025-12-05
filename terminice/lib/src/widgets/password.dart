import '../style/theme.dart';
import '../system/key_events.dart';
import '../system/hints.dart';
import '../system/framed_layout.dart';
import '../system/prompt_runner.dart';

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
    String buffer = '';
    bool showPlain = false;
    bool confirmed = false;
    final cursorBlink = CursorBlink();

    void render(RenderOutput out) {
      // Top border
      final frame = FramedLayout(label, theme: theme);
      final topLine = frame.top();
      if (style.boldPrompt) {
        out.writeln('${theme.bold}$topLine${theme.reset}');
      } else {
        out.writeln(topLine);
      }

      // Input display
      final display = showPlain ? buffer : maskChar * buffer.length;
      final cursor =
          cursorBlink.isVisible ? '${theme.accent}▋${theme.reset}' : ' ';
      final content = display.isEmpty
          ? '${theme.dim}(empty)${theme.reset}'
          : '$display$cursor';

      out.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} ${theme.accent}${style.arrow}${theme.reset} $content');

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
        } else if (event.type == KeyEventType.backspace) {
          if (buffer.isNotEmpty) {
            buffer = buffer.substring(0, buffer.length - 1);
          }
        } else if (event.type == KeyEventType.char && event.char != null) {
          buffer += event.char!;
        }

        return null; // continue loop
      },
    );

    if (!confirmed) return '';
    return buffer;
  }
}
