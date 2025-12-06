import 'dart:io';

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

  final term = Terminal.enterRaw();
  Terminal.hideCursor();

  void renderBase() {
    Terminal.clearAndHome();
    final top = FrameRenderer.titleWithBorders('Demo App', theme);
    stdout.writeln('${theme.bold}$top${theme.reset}');
    stdout.writeln(
        '${theme.gray}${theme.style.borderVertical}${theme.reset} Press ${Hints.key('?', theme)} to view hotkeys');
    stdout.writeln(FrameRenderer.bottomLine('Demo App', theme));
  }

  try {
    renderBase();
    while (true) {
      final ev = KeyEventReader.read();
      if (ev.type == KeyEventType.ctrlC || ev.type == KeyEventType.esc) {
        break;
      }
      if (ev.type == KeyEventType.char && ev.char == '?') {
        guide.run();
        renderBase();
      }
    }
  } finally {
    term.restore();
    Terminal.showCursor();
  }
}
