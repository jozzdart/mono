import 'dart:async';
import 'dart:io';

import '../style/theme.dart';

/// StatusLine – persistent, theme-aware line rendered at the bottom
/// of the terminal for live status updates.
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

  Timer? _spinnerTimer;
  int _spinnerPhase = 0;
  String _message = '';
  bool _running = false;

  StatusLine({
    required this.label,
    this.theme = PromptTheme.dark,
    this.showSpinner = true,
    this.spinnerInterval = const Duration(milliseconds: 120),
  });

  /// Begin rendering the persistent status line.
  void start() {
    if (_running) return;
    _running = true;
    _render();
    if (showSpinner) {
      _spinnerTimer = Timer.periodic(spinnerInterval, (_) {
        _spinnerPhase = (_spinnerPhase + 1) % _spinnerFrames.length;
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
    _render(icon: '${theme.checkboxOn}✔${theme.reset}');
    _stopSpinner();
  }

  /// Show an error state and freeze the spinner.
  void error(String message) {
    _message = message;
    _render(icon: '${theme.highlight}✖${theme.reset}');
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

    // Build content line aligned with ThemeDemo borders/accents.
    final prefix = '${theme.gray}${s.borderBottom}${theme.reset}';
    final title = '${theme.selection} $label ${theme.reset}';
    final spin = icon ?? (showSpinner ? _spinnerFrames[_spinnerPhase] : ' ');
    final line = StringBuffer()
      ..write(prefix)
      ..write(' ')
      ..write(title)
      ..write('  ')
      ..write('${theme.accent}$spin${theme.reset}')
      ..write('  ')
      ..write(_styledMessage(_message));

    _writeBottom(line.toString());
  }

  String _styledMessage(String msg) {
    if (msg.isEmpty) return '';
    return '${theme.gray}$msg${theme.reset}';
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

  static const List<String> _spinnerFrames = [
    '⠋',
    '⠙',
    '⠹',
    '⠸',
    '⠼',
    '⠴',
    '⠦',
    '⠧',
    '⠇',
    '⠏'
  ];
}
