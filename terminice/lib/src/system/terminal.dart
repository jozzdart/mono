import 'dart:io';

/// Terminal utilities used across widgets to manage raw mode and input.
class Terminal {
  /// Puts stdin into raw mode (no echo, no line buffering) and returns
  /// a [TerminalState] that can be used to restore the original settings.
  static TerminalState enterRaw() {
    final origEcho = stdin.echoMode;
    final origLineMode = stdin.lineMode;
    stdin.echoMode = false;
    stdin.lineMode = false;
    return TerminalState(origEcho: origEcho, origLineMode: origLineMode);
  }

  /// Attempts to read the next byte for multi-byte escape sequences.
  /// Returns null if no byte is available.
  static int? tryReadNextByte(
      {Duration delay = const Duration(milliseconds: 2)}) {
    try {
      sleep(delay);
      if (stdin.hasTerminal) return stdin.readByteSync();
    } catch (_) {}
    return null;
  }

  /// Clears the screen and moves cursor to home position.
  static void clearAndHome() {
    stdout
      ..write('\x1B[2J')
      ..write('\x1B[H');
  }

  /// Hides the cursor.
  static void hideCursor() {
    stdout.write('\x1B[?25l');
  }

  /// Shows the cursor.
  static void showCursor() {
    stdout.write('\x1B[?25h');
  }
}

/// Captures original terminal state and restores it on [restore].
class TerminalState {
  final bool origEcho;
  final bool origLineMode;

  TerminalState({required this.origEcho, required this.origLineMode});

  void restore() {
    try {
      if (!stdin.hasTerminal) return;
    } catch (_) {
      return;
    }
    try {
      stdin.echoMode = origEcho;
    } catch (_) {}
    try {
      stdin.lineMode = origLineMode;
    } catch (_) {}
  }
}
