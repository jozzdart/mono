import 'dart:io';

import '../style/theme.dart';
import '../system/widget_frame.dart';

/// StatusLine – persistent, theme-aware line rendered at the bottom
/// of the terminal for live status updates.
///
/// **Usage:**
/// ```dart
/// final status = StatusLine(label: 'Build');
/// status.show('Compiling...');
/// // ... work ...
/// status.show('Linking...');
/// status.success('Done');
/// ```
class StatusLine with Themeable {
  final String label;
  @override
  final PromptTheme theme;

  late final InlineStyle _inline;
  String _message = '';
  int _spinnerPhase = 0;

  StatusLine({
    required this.label,
    this.theme = PromptTheme.dark,
  }) {
    _inline = InlineStyle(theme);
  }

  @override
  StatusLine copyWithTheme(PromptTheme theme) {
    return StatusLine(
      label: label,
      theme: theme,
    );
  }

  /// Show or update the status line message.
  void show(String message, {int? spinnerPhase}) {
    _message = message;
    if (spinnerPhase != null) _spinnerPhase = spinnerPhase;
    _render();
  }

  /// Show a success state.
  void success(String message) {
    _message = message;
    _render(icon: _inline.successIcon());
  }

  /// Show an error state.
  void error(String message) {
    _message = message;
    _render(icon: _inline.errorIcon());
  }

  /// Show a warning state.
  void warning(String message) {
    _message = message;
    _render(icon: _inline.warnIcon());
  }

  /// Advance the spinner phase.
  void tick() {
    _spinnerPhase++;
    _render();
  }

  void _render({String? icon}) {
    final s = theme.style;

    final prefix = _inline.gray(s.borderBottom);
    final title = _inline.selection(' $label ');
    final spin = icon ?? _inline.spinner(_spinnerPhase);
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
    stdout.write('\x1B7'); // Save cursor
    stdout.write('\x1B[999;1H'); // Move to bottom
    stdout
      ..write('\x1B[2K') // Clear line
      ..writeln(text);
    stdout.write('\x1B8'); // Restore cursor
  }
}
