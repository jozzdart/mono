import '../style/theme.dart';
import '../system/key_bindings.dart';
import '../system/prompt_runner.dart';
import '../system/text_input_buffer.dart';
import '../system/widget_frame.dart';

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
    // Use centralized text input for buffer handling
    final buffer = TextInputBuffer();
    bool showPlain = false;
    bool confirmed = false;
    final cursorBlink = CursorBlink();

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings.password(
      buffer: buffer,
      onRevealToggle: () => showPlain = !showPlain,
      onConfirm: () {
        if (allowEmpty || buffer.isNotEmpty) {
          confirmed = true;
          return KeyActionResult.confirmed;
        }
        return KeyActionResult.handled;
      },
    );

    // Use WidgetFrame for consistent frame rendering
    final frame = WidgetFrame(
      title: label,
      theme: theme,
      bindings: bindings,
    );

    void render(RenderOutput out) {
      frame.render(out, (ctx) {
        // Input display
        final display = showPlain ? buffer.text : maskChar * buffer.length;
        final cursor =
            cursorBlink.isVisible ? '${theme.accent}▋${theme.reset}' : ' ';
        final content =
            buffer.isEmpty ? ctx.lb.emptyMessage('empty') : '$display$cursor';

        ctx.gutterLine('${ctx.lb.arrowAccent()} $content');
      });
    }

    final runner = PromptRunner(hideCursor: true);
    runner.runAsyncWithBindings(
      render: render,
      cursorBlink: cursorBlink,
      bindings: bindings,
    );

    if (!confirmed) return '';
    return buffer.text;
  }
}
