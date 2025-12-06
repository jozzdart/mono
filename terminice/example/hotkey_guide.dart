import 'package:terminice/terminice.dart';

void main() {
  final theme = PromptTheme.dark; // Try .matrix, .fire, .pastel

  final guide = HotkeyGuide([
    [Hints.key('?', theme), 'Show this guide'],
    [Hints.key('↑ / ↓', theme), 'Navigate'],
    [Hints.key('← / →', theme), 'Move between panes'],
    [Hints.key('Enter', theme), 'Select / confirm'],
    [Hints.key('Esc', theme), 'Back / close'],
    [Hints.key('Ctrl+C', theme), 'Exit'],
  ], theme: theme, title: 'Hotkey Guide');

  // Use TerminalSession for raw mode + cursor, RenderOutput for partial clearing
  final session = TerminalSession(hideCursor: true, rawMode: true);
  session.start();

  final out = RenderOutput();

  void renderBase() {
    out.clear(); // Only clears our output, preserves terminal history
    final top = FrameRenderer.titleWithBorders('Demo App', theme);
    out.writeln('${theme.bold}$top${theme.reset}');
    out.writeln(
        '${theme.gray}${theme.style.borderVertical}${theme.reset} Press ${Hints.key('?', theme)} to view hotkeys');
    out.writeln(FrameRenderer.bottomLine('Demo App', theme));
  }

  try {
    renderBase();
    while (true) {
      final ev = KeyEventReader.read();
      if (ev.type == KeyEventType.ctrlC || ev.type == KeyEventType.esc) {
        break;
      }
      if (ev.type == KeyEventType.char && ev.char == '?') {
        out.clear(); // Clear base UI before showing guide
        guide.run();
        renderBase(); // Redraw base UI after guide closes
      }
    }
  } finally {
    session.end();
    out.clear(); // Clean exit
  }
}
