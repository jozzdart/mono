import '../style/theme.dart';

/// Badge – inline, theme-aware colored label (e.g., "SUCCESS", "FAILED").
///
/// Designed to align with ThemeDemo styling and the shared PromptTheme system.
/// Use it to decorate logs or inline outputs with compact, readable labels.
///
/// Example:
///   stdout.writeln('Build: ' + Badge.success('SUCCESS').render());
class Badge {
  final String text;
  final BadgeTone tone;
  final PromptTheme theme;
  final bool inverted; // uses inverse video for a filled look
  final bool bracketed; // wrap with [ ] for chip-like look
  final bool bold;

  const Badge(
    this.text, {
    this.tone = BadgeTone.info,
    this.theme = PromptTheme.dark,
    this.inverted = true,
    this.bracketed = true,
    this.bold = true,
  });

  /// Convenience constructors
  const Badge.success(
    String text, {
    PromptTheme theme = PromptTheme.dark,
    bool inverted = true,
    bool bracketed = true,
    bool bold = true,
  }) : this(text,
          tone: BadgeTone.success,
          theme: theme,
          inverted: inverted,
          bracketed: bracketed,
          bold: bold,
        );

  const Badge.info(
    String text, {
    PromptTheme theme = PromptTheme.dark,
    bool inverted = true,
    bool bracketed = true,
    bool bold = true,
  }) : this(text,
          tone: BadgeTone.info,
          theme: theme,
          inverted: inverted,
          bracketed: bracketed,
          bold: bold,
        );

  const Badge.warning(
    String text, {
    PromptTheme theme = PromptTheme.dark,
    bool inverted = true,
    bool bracketed = true,
    bool bold = true,
  }) : this(text,
          tone: BadgeTone.warning,
          theme: theme,
          inverted: inverted,
          bracketed: bracketed,
          bold: bold,
        );

  const Badge.danger(
    String text, {
    PromptTheme theme = PromptTheme.dark,
    bool inverted = true,
    bool bracketed = true,
    bool bold = true,
  }) : this(text,
          tone: BadgeTone.danger,
          theme: theme,
          inverted: inverted,
          bracketed: bracketed,
          bold: bold,
        );

  const Badge.neutral(
    String text, {
    PromptTheme theme = PromptTheme.dark,
    bool inverted = true,
    bool bracketed = true,
    bool bold = true,
  }) : this(text,
          tone: BadgeTone.neutral,
          theme: theme,
          inverted: inverted,
          bracketed: bracketed,
          bold: bold,
        );

  /// Returns the colored, inline badge string.
  String render() {
    final color = _toneColor(tone, theme);
    final label = ' $text ';

    if (bracketed) {
      if (inverted) {
        // Filled look: invert with the tone color across the whole chip
        final body = '[$label]';
        return '${bold ? theme.bold : ''}${theme.inverse}$color$body${theme.reset}';
      }
      // Outline look: keep brackets neutral, color the text
      final inner = '${bold ? theme.bold : ''}$color$label${theme.reset}';
      return '[$inner]';
    }

    if (inverted) {
      return '${bold ? theme.bold : ''}${theme.inverse}$color$label${theme.reset}';
    }
    return '${bold ? theme.bold : ''}$color$label${theme.reset}';
  }

  @override
  String toString() => render();

  static String _toneColor(BadgeTone tone, PromptTheme theme) {
    switch (tone) {
      case BadgeTone.neutral:
        return theme.gray;
      case BadgeTone.info:
        return theme.accent;
      case BadgeTone.success:
        return theme.checkboxOn;
      case BadgeTone.warning:
        return theme.highlight;
      case BadgeTone.danger:
        // Align with StatusLine.error which also uses highlight.
        return theme.highlight;
    }
  }
}

enum BadgeTone { neutral, info, success, warning, danger }


