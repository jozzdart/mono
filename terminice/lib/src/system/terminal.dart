import 'dart:io';

/// Provides safe, cached access to terminal dimensions with sensible defaults.
///
/// Instead of duplicating terminal size queries across widgets, use this
/// centralized utility:
///
/// ```dart
/// final cols = TerminalInfo.columns;
/// final rows = TerminalInfo.rows;
/// final size = TerminalInfo.size;
/// ```
///
/// **Why centralize?**
/// - Consistent fallback defaults (80×24)
/// - Single point for error handling
/// - Easy to test/mock
/// - Reduces boilerplate in widgets
class TerminalInfo {
  /// Default fallback width when terminal is unavailable.
  static const int defaultColumns = 80;

  /// Default fallback height when terminal is unavailable.
  static const int defaultRows = 24;

  /// Returns the current terminal width in columns.
  ///
  /// Falls back to [defaultColumns] if:
  /// - No terminal is attached
  /// - An error occurs querying the terminal
  static int get columns {
    try {
      if (stdout.hasTerminal) return stdout.terminalColumns;
    } catch (_) {}
    return defaultColumns;
  }

  /// Returns the current terminal height in rows.
  ///
  /// Falls back to [defaultRows] if:
  /// - No terminal is attached
  /// - An error occurs querying the terminal
  static int get rows {
    try {
      if (stdout.hasTerminal) return stdout.terminalLines;
    } catch (_) {}
    return defaultRows;
  }

  /// Returns both dimensions as a record.
  ///
  /// Usage:
  /// ```dart
  /// final (:columns, :rows) = TerminalInfo.size;
  /// ```
  static ({int columns, int rows}) get size => (columns: columns, rows: rows);

  /// Whether a terminal is available.
  static bool get hasTerminal {
    try {
      return stdout.hasTerminal;
    } catch (_) {
      return false;
    }
  }
}

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
