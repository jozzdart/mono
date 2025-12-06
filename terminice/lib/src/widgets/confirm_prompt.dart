import '../style/theme.dart';
import '../system/key_bindings.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

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
    bool selectedYes = defaultYes;

    // Use KeyBindings for declarative, composable key handling
    final bindings = KeyBindings.togglePrompt(
      onToggle: () => selectedYes = !selectedYes,
    );

    // Use WidgetFrame for consistent frame rendering
    final frame = WidgetFrame(
      title: label,
      theme: theme,
      bindings: bindings,
    );

    void render(RenderOutput out) {
      frame.render(out, (ctx) {
        // Message with arrow
        ctx.emptyLine();
        ctx.line(
            ' ${ctx.lb.arrowAccent()} ${theme.bold}$message${theme.reset}');
        ctx.emptyLine();

        // Static "highlighted" buttons (no animation)
        final yes = selectedYes
            ? '${theme.inverse}${theme.accent} $yesLabel ${theme.reset}'
            : '${theme.dim}$yesLabel${theme.reset}';
        final no = !selectedYes
            ? '${theme.inverse}${theme.accent} $noLabel ${theme.reset}'
            : '${theme.dim}$noLabel${theme.reset}';

        // Balanced layout
        ctx.line('   $yes   $no\n');
      });
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: render,
      bindings: bindings,
    );

    if (result == PromptResult.cancelled) return false;
    return selectedYes;
  }
}
