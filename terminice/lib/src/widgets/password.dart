import 'dart:async';
import 'dart:io';
import '../style/theme.dart';
import '../system/terminal.dart';
import '../system/key_events.dart';
import '../system/frame_renderer.dart';
import '../system/hints.dart';

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
    final term = Terminal.enterRaw();

    String buffer = '';
    bool showPlain = false;
    bool cancelled = false;
    bool cursorVisible = true;
    Timer? blinkTimer;

    void cleanup() {
      blinkTimer?.cancel();
      term.restore();
      Terminal.showCursor();
    }

    // Render function — must be declared before startBlink
    void render() {
      Terminal.clearAndHome();

      // Top border
      final topLine = style.showBorder
          ? FrameRenderer.titleWithBorders(label, theme)
          : FrameRenderer.plainTitle(label, theme);
      if (style.boldPrompt) {
        stdout.writeln('${theme.bold}$topLine${theme.reset}');
      } else {
        stdout.writeln(topLine);
      }

      // Input display
      final display = showPlain ? buffer : maskChar * buffer.length;
      final cursor = cursorVisible ? '${theme.accent}▋${theme.reset}' : ' ';
      final content = display.isEmpty
          ? '${theme.dim}(empty)${theme.reset}'
          : '$display$cursor';

      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} ${theme.accent}${style.arrow}${theme.reset} $content');

      // Bottom line
      if (style.showBorder) {
        stdout.writeln(FrameRenderer.bottomLine(label, theme));
      }

      // Hints
      final hints = <String>[
        Hints.hint('Ctrl+R', 'reveal', theme),
        Hints.hint('Enter', 'confirm', theme),
        Hints.hint('Esc', 'cancel', theme),
      ];
      stdout.writeln(Hints.bullets(hints, theme));
      Terminal.hideCursor();
    }

    // Blink timer after render defined
    void startBlink() {
      blinkTimer?.cancel();
      blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        cursorVisible = !cursorVisible;
        render();
      });
    }

    // Initial render
    render();
    startBlink();

    try {
      while (true) {
        final ev = KeyEventReader.read();
        cursorVisible = true; // always make cursor visible on interaction
        blinkTimer?.cancel();
        startBlink();

        if (ev.type == KeyEventType.enter) {
          if (allowEmpty || buffer.isNotEmpty) break;
        } else if (ev.type == KeyEventType.ctrlC ||
            ev.type == KeyEventType.esc) {
          cancelled = true;
          break;
        } else if (ev.type == KeyEventType.ctrlR) {
          showPlain = !showPlain;
        } else if (ev.type == KeyEventType.backspace) {
          if (buffer.isNotEmpty)
            buffer = buffer.substring(0, buffer.length - 1);
        } else if (ev.type == KeyEventType.char && ev.char != null) {
          buffer += ev.char!;
        }

        render();
      }
    } finally {
      cleanup();
    }

    Terminal.clearAndHome();
    if (cancelled) return '';
    return buffer;
  }
}
