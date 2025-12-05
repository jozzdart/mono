import '../style/theme.dart';
import '../system/key_events.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/prompt_runner.dart';

/// ConfirmPrompt – elegant instant confirmation dialog (no timers or delays).
///
/// Controls:
/// - ← / → or ↑ / ↓ toggle between options
/// - Enter confirms
/// - Esc / Ctrl+C cancels (returns false)
class ConfirmPrompt {
  final String label;
  final String message;
  final String yesLabel;
  final String noLabel;
  final PromptTheme theme;
  final bool defaultYes;

  ConfirmPrompt({
    required this.label,
    required this.message,
    this.yesLabel = 'Yes',
    this.noLabel = 'No',
    this.theme = PromptTheme.dark,
    this.defaultYes = true,
  });

  bool run() {
    final style = theme.style;
    bool selectedYes = defaultYes;

    void render(RenderOutput out) {
      // Header
      final frame = FramedLayout(label, theme: theme);
      final top = frame.top();
      out.writeln(
        style.boldPrompt ? '${theme.bold}$top${theme.reset}' : top,
      );

      // Message
      out.writeln('');
      out.writeln(
        ' ${theme.accent}${style.arrow}${theme.reset} ${theme.bold}$message${theme.reset}',
      );
      out.writeln('');

      // Static "highlighted" buttons (no animation)
      final yes = selectedYes
          ? '${theme.inverse}${theme.accent} $yesLabel ${theme.reset}'
          : '${theme.dim}$yesLabel${theme.reset}';
      final no = !selectedYes
          ? '${theme.inverse}${theme.accent} $noLabel ${theme.reset}'
          : '${theme.dim}$noLabel${theme.reset}';

      // Balanced layout
      out.writeln('   $yes   $no\n');

      // Optional bottom line
      if (style.showBorder) {
        out.writeln(frame.bottom());
      }

      // Hints
      out.writeln(Hints.bullets([
        Hints.hint('←/→', 'toggle', theme),
        Hints.hint('Enter', 'confirm', theme),
        Hints.hint('Esc', 'cancel', theme),
      ], theme));
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.run(
      render: render,
      onKey: (event) {
        // Cancel instantly
        if (event.type == KeyEventType.esc ||
            event.type == KeyEventType.ctrlC) {
          return PromptResult.cancelled;
        }

        // Confirm instantly
        if (event.type == KeyEventType.enter) {
          return PromptResult.confirmed;
        }

        // Toggle instantly
        if (event.type == KeyEventType.arrowLeft ||
            event.type == KeyEventType.arrowRight ||
            event.type == KeyEventType.arrowUp ||
            event.type == KeyEventType.arrowDown ||
            event.type == KeyEventType.space) {
          selectedYes = !selectedYes;
        }

        return null; // continue loop
      },
    );

    if (result == PromptResult.cancelled) return false;
    return selectedYes;
  }
}
