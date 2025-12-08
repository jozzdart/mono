import '../style/theme.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart' as wf;

/// Badge – inline, theme-aware colored label (e.g., "SUCCESS", "FAILED").
///
/// Use it to decorate logs or inline outputs with compact, readable labels.
///
/// **Example:**
/// ```dart
/// Badge.success('OK').show();
/// Badge.warning('SLOW').withMatrixTheme().show();
///
/// // Or get the string to use inline:
/// print('Build: ${Badge.success('PASS').render()}');
/// ```
class Badge with Themeable {
  final String text;
  final BadgeTone tone;
  @override
  final PromptTheme theme;
  final bool inverted;
  final bool bracketed;
  final bool bold;

  Badge(
    this.text, {
    this.tone = BadgeTone.info,
    this.theme = PromptTheme.dark,
    this.inverted = true,
    this.bracketed = true,
    this.bold = true,
  });

  @override
  Badge copyWithTheme(PromptTheme theme) {
    return Badge(
      text,
      tone: tone,
      theme: theme,
      inverted: inverted,
      bracketed: bracketed,
      bold: bold,
    );
  }

  /// Convenience constructors
  Badge.success(
    String text, {
    PromptTheme theme = PromptTheme.dark,
    bool inverted = true,
    bool bracketed = true,
    bool bold = true,
  }) : this(
          text,
          tone: BadgeTone.success,
          theme: theme,
          inverted: inverted,
          bracketed: bracketed,
          bold: bold,
        );

  Badge.info(
    String text, {
    PromptTheme theme = PromptTheme.dark,
    bool inverted = true,
    bool bracketed = true,
    bool bold = true,
  }) : this(
          text,
          tone: BadgeTone.info,
          theme: theme,
          inverted: inverted,
          bracketed: bracketed,
          bold: bold,
        );

  Badge.warning(
    String text, {
    PromptTheme theme = PromptTheme.dark,
    bool inverted = true,
    bool bracketed = true,
    bool bold = true,
  }) : this(
          text,
          tone: BadgeTone.warning,
          theme: theme,
          inverted: inverted,
          bracketed: bracketed,
          bold: bold,
        );

  Badge.danger(
    String text, {
    PromptTheme theme = PromptTheme.dark,
    bool inverted = true,
    bool bracketed = true,
    bool bold = true,
  }) : this(
          text,
          tone: BadgeTone.danger,
          theme: theme,
          inverted: inverted,
          bracketed: bracketed,
          bold: bold,
        );

  Badge.neutral(
    String text, {
    PromptTheme theme = PromptTheme.dark,
    bool inverted = true,
    bool bracketed = true,
    bool bold = true,
  }) : this(
          text,
          tone: BadgeTone.neutral,
          theme: theme,
          inverted: inverted,
          bracketed: bracketed,
          bold: bold,
        );

  /// Shows the badge using centralized output.
  void show() {
    final out = RenderOutput();
    out.writeln(render());
  }

  /// Returns the colored badge string (for inline use).
  String render() {
    final inline = wf.InlineStyle(theme);
    return inline.badge(
      text,
      tone: _toInlineTone(tone),
      inverted: inverted,
      bracketed: bracketed,
      bold: bold,
    );
  }

  @override
  String toString() => render();

  static wf.BadgeTone _toInlineTone(BadgeTone t) {
    switch (t) {
      case BadgeTone.neutral:
        return wf.BadgeTone.neutral;
      case BadgeTone.info:
        return wf.BadgeTone.info;
      case BadgeTone.success:
        return wf.BadgeTone.success;
      case BadgeTone.warning:
        return wf.BadgeTone.warning;
      case BadgeTone.danger:
        return wf.BadgeTone.danger;
    }
  }
}

/// Tone for badges: influences the color.
enum BadgeTone { neutral, info, success, warning, danger }
