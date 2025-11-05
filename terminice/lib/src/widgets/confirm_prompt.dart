import 'dart:io';
import '../style/theme.dart';
import '../system/terminal.dart';
import '../system/key_events.dart';
import '../system/frame_renderer.dart';
import '../system/hints.dart';

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
    final term = Terminal.enterRaw();

    bool selectedYes = defaultYes;
    bool cancelled = false;

    void cleanup() {
      term.restore();
      Terminal.showCursor();
    }

    void render() {
      Terminal.clearAndHome();

      // Header
      final top = style.showBorder
          ? FrameRenderer.titleWithBorders(label, theme)
          : FrameRenderer.plainTitle(label, theme);
      stdout.writeln(
        style.boldPrompt ? '${theme.bold}$top${theme.reset}' : top,
      );

      // Message
      stdout.writeln('');
      stdout.writeln(
        ' ${theme.accent}${style.arrow}${theme.reset} ${theme.bold}$message${theme.reset}',
      );
      stdout.writeln('');

      // Static “highlighted” buttons (no animation)
      final yes = selectedYes
          ? '${theme.inverse}${theme.accent} $yesLabel ${theme.reset}'
          : '${theme.dim}$yesLabel${theme.reset}';
      final no = !selectedYes
          ? '${theme.inverse}${theme.accent} $noLabel ${theme.reset}'
          : '${theme.dim}$noLabel${theme.reset}';

      // Balanced layout
      stdout.writeln('   $yes   $no\n');

      // Optional bottom line
      if (style.showBorder) {
        stdout.writeln(FrameRenderer.bottomLine(label, theme));
      }

      // Hints
      stdout.writeln(Hints.bullets([
        Hints.hint('←/→', 'toggle', theme),
        Hints.hint('Enter', 'confirm', theme),
        Hints.hint('Esc', 'cancel', theme),
      ], theme));

      Terminal.hideCursor();
    }

    // Draw initial state
    render();

    try {
      while (true) {
        final ev = KeyEventReader.read();

        // Cancel instantly
        if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
          cancelled = true;
          break;
        }

        // Confirm instantly
        if (ev.type == KeyEventType.enter) break;

        // Toggle instantly
        if (ev.type == KeyEventType.arrowLeft ||
            ev.type == KeyEventType.arrowRight ||
            ev.type == KeyEventType.arrowUp ||
            ev.type == KeyEventType.arrowDown ||
            ev.type == KeyEventType.space) {
          selectedYes = !selectedYes;
          render();
        }
      }
    } finally {
      cleanup();
    }

    Terminal.clearAndHome();
    if (cancelled) return false;
    return selectedYes;
  }
}
