import 'dart:io';

import 'package:mono_core/mono_core.dart';

class StdLogger implements Logger {
  const StdLogger();

  @override
  void log(String message, {String? scope, String level = 'info'}) {
    final prefix = scope != null ? '[$scope]' : '';
    final line =
        '${DateTime.now().toIso8601String()} [$level] $prefix $message';
    if (level == 'error') {
      stderr.writeln(line);
    } else {
      stdout.writeln(line);
    }
  }
}

/// Pretty logger configuration toggles.
class PrettyLogConfig {
  const PrettyLogConfig({
    this.showColors = true,
    this.showIcons = true,
    this.showTimestamp = false,
  });

  final bool showColors;
  final bool showIcons;
  final bool showTimestamp;
}

class PrettyLogger implements Logger {
  const PrettyLogger(this.config);

  final PrettyLogConfig config;

  static const _ansiReset = '\x1B[0m';
  static const _ansiBold = '\x1B[1m';
  static const _ansiDim = '\x1B[2m';
  static const _fgRed = '\x1B[31m';
  static const _fgGreen = '\x1B[32m';
  static const _fgYellow = '\x1B[33m';
  static const _fgBlue = '\x1B[34m';
  static const _fgMagenta = '\x1B[35m';
  static const _fgWhiteBright = '\x1B[97m';

  @override
  void log(String message, {String? scope, String level = 'info'}) {
    final ts = config.showTimestamp
        ? '${DateTime.now().toIso8601String()} '
        : '';
    final scopePrefix = scope != null && scope.isNotEmpty
        ? _maybeColor('[$scope]', _ansiDim)
        : '';

    final styledLevel = _styledLevel(level);
    final icon = config.showIcons ? _iconFor(level) : '';

    final parts = <String>[];
    if (ts.isNotEmpty) parts.add(ts.trimRight());
    if (icon.isNotEmpty) parts.add(icon);
    if (styledLevel.isNotEmpty) parts.add(styledLevel);
    if (scopePrefix.isNotEmpty) parts.add(scopePrefix);
    parts.add(message);

    final line = parts.join(' ');
    if (level == 'error') {
      stderr.writeln(line);
    } else {
      stdout.writeln(line);
    }
  }

  String _styledLevel(String level) {
    // Render a compact level label when icons are disabled; otherwise keep minimal
    if (config.showIcons) {
      // Keep level label subtle when icons are present
      return config.showColors ? _ansiDim + level + _ansiReset : level;
    }
    switch (level) {
      case 'error':
        return _maybeColor('[error]', _fgRed + _ansiBold);
      case 'warn':
        return _maybeColor('[warn]', _fgYellow + _ansiBold);
      case 'success':
        return _maybeColor('[ok]', _fgGreen + _ansiBold);
      case 'debug':
        return _maybeColor('[debug]', _fgMagenta);
      case 'header':
        return _maybeColor('[*]', _fgWhiteBright + _ansiBold);
      case 'divider':
        return '';
      default:
        return _maybeColor('[info]', _fgBlue);
    }
  }

  String _iconFor(String level) {
    switch (level) {
      case 'error':
        return _maybeColor('✖', _fgRed);
      case 'warn':
        return _maybeColor('⚠', _fgYellow);
      case 'success':
        return _maybeColor('✔', _fgGreen);
      case 'header':
        return _maybeColor('▸', _fgWhiteBright);
      case 'debug':
        return _maybeColor('•', _fgMagenta);
      case 'divider':
        return '';
      default:
        return _maybeColor('•', _fgBlue);
    }
  }

  String _maybeColor(String text, String color) {
    if (!config.showColors) return text;
    return '$color$text$_ansiReset';
  }
}
