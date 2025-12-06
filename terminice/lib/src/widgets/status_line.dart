import 'dart:async';
import 'dart:io';

import '../style/theme.dart';
import '../system/widget_frame.dart';

/// StatusLine – persistent, theme-aware line rendered at the bottom
/// of the terminal for live status updates.
///
/// Uses the centralized [InlineStyle] system for consistent theming.
///
/// Usage:
///   final s = StatusLine(label: 'Build', theme: PromptTheme.pastel)..start();
///   s.update('Compiling sources');
///   // ... work ...
///   s.success('Done');
///   s.stop();
class StatusLine {
  final String label;
  final PromptTheme theme;
  final bool showSpinner;
  final Duration spinnerInterval;

  late final InlineStyle _inline;
  Timer? _spinnerTimer;
  int _spinnerPhase = 0;
  String _message = '';
  bool _running = false;

  StatusLine({
    required this.label,
    this.theme = PromptTheme.dark,
    this.showSpinner = true,
    this.spinnerInterval = const Duration(milliseconds: 120),
  }) {
    _inline = InlineStyle(theme);
  }

  /// Begin rendering the persistent status line.
  void start() {
    if (_running) return;
    _running = true;
    _render();
    if (showSpinner) {
      _spinnerTimer = Timer.periodic(spinnerInterval, (_) {
        _spinnerPhase++;
        _render();
      });
    }
  }

  /// Update the message on the status line.
  void update(String message) {
    _message = message;
    _render();
  }

  /// Show a success state and freeze the spinner.
  void success(String message) {
    _message = message;
    _render(icon: _inline.successIcon());
    _stopSpinner();
  }

  /// Show an error state and freeze the spinner.
  void error(String message) {
    _message = message;
    _render(icon: _inline.errorIcon());
    _stopSpinner();
  }

  /// Show a warning state.
  void warning(String message) {
    _message = message;
    _render(icon: _inline.warnIcon());
    _stopSpinner();
  }

  /// Stop rendering (does not clear the last line).
  void stop() {
    _stopSpinner();
    _running = false;
  }

  void _stopSpinner() {
    _spinnerTimer?.cancel();
    _spinnerTimer = null;
  }

  void _render({String? icon}) {
    if (!_running) return;
    final s = theme.style;

    // Build content line using InlineStyle for consistent theming
    final prefix = _inline.gray(s.borderBottom);
    final title = _inline.selection(' $label ');
    final spin = icon ?? (showSpinner ? _inline.spinner(_spinnerPhase) : ' ');
    final msg = _message.isEmpty ? '' : _inline.gray(_message);

    final line = StringBuffer()
      ..write(prefix)
      ..write(' ')
      ..write(title)
      ..write('  ')
      ..write(spin)
      ..write('  ')
      ..write(msg);

    _writeBottom(line.toString());
  }

  void _writeBottom(String text) {
    // Save cursor position
    stdout.write('\x1B7');
    // Move to last row, column 1 (clamped by terminal)
    stdout.write('\x1B[999;1H');
    // Clear the line and write content
    stdout
      ..write('\x1B[2K')
      ..writeln(text);
    // Restore cursor position
    stdout.write('\x1B8');
  }
}
