import 'dart:io';

import '../style/theme.dart';

/// Rendering context provided to every TerminalWidget during build.
///
/// Contains theme and environment information (e.g., terminal width),
/// without exposing stdout directly to widgets.
class RenderContext {
  final PromptTheme theme;
  final int terminalColumns;
  final bool colorEnabled;

  const RenderContext({
    this.theme = const PromptTheme(),
    this.terminalColumns = 100,
    this.colorEnabled = true,
  });

  /// Create a context using the current process terminal when available.
  factory RenderContext.fromTerminal({
    PromptTheme theme = const PromptTheme(),
    bool colorEnabled = true,
  }) {
    int cols;
    try {
      cols = stdout.hasTerminal ? stdout.terminalColumns : 100;
    } catch (_) {
      cols = 100;
    }
    return RenderContext(
      theme: theme,
      terminalColumns: cols,
      colorEnabled: colorEnabled,
    );
  }
}


