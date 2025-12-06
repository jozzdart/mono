import '../style/theme.dart';
import '../system/widget_frame.dart';

/// Pretty-prints text with simple syntax and color rules.
///
/// Aligns with ThemeDemo styling: titled frame, left gutter using the
/// theme's vertical border glyph, and tasteful use of accent/highlight colors.
///
/// Uses the centralized [SyntaxHighlighter] for consistent syntax coloring.
///
/// **Mixins:** Implements [Themeable] for fluent theme configuration:
/// ```dart
/// Highlight(code).withMatrixTheme().show();
/// ```
class Highlight with Themeable {
  final String text;
  @override
  final PromptTheme theme;
  final String language; // 'auto', 'dart', 'json', 'shell', 'plain'
  final String? title;
  final bool color; // enable/disable ANSI coloring entirely
  final bool guides; // draw underline guides when color is off

  Highlight(
    this.text, {
    this.theme = PromptTheme.dark,
    this.language = 'auto',
    this.title,
    this.color = true,
    this.guides = false,
  });

  @override
  Highlight copyWithTheme(PromptTheme theme) {
    return Highlight(
      text,
      theme: theme,
      language: language,
      title: title,
      color: color,
      guides: guides,
    );
  }

  /// Render highlighted output within a themed frame.
  void show() {
    final label = title ?? _defaultTitle(language);

    if (color) {
      final frame = WidgetFrame(title: label, theme: theme);
      frame.show((ctx) {
        final highlighter = SyntaxHighlighter(theme);
        for (final line in text.split('\n')) {
          final colored = _highlightLine(line, highlighter);
          ctx.gutterLine(colored);
        }
      });
    } else {
      // Non-colored output uses simpler rendering
      final style = theme.style;
      final frame = WidgetFrame(title: label, theme: theme);
      frame.show((ctx) {
        for (final line in text.split('\n')) {
          ctx.line('${style.borderVertical} $line');
          if (guides) {
            final guide = _guideLine(line, _resolveLanguage(line));
            if (guide.trim().isNotEmpty) {
              ctx.line('${style.borderVertical} $guide');
            }
          }
        }
      });
    }
  }

  String _highlightLine(String line, SyntaxHighlighter highlighter) {
    final lang = _resolveLanguage(line);
    switch (lang) {
      case 'dart':
        return highlighter.dartLine(line);
      case 'json':
        return highlighter.jsonLine(line);
      case 'shell':
        return highlighter.shellLine(line);
      default:
        return line;
    }
  }

  String _resolveLanguage(String line) {
    if (language != 'auto') return language;
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) return 'json';
    if (trimmed.startsWith('#')) return 'shell';
    if (trimmed.startsWith('import ') || trimmed.contains(' void ') ||
        trimmed.contains(' class ') || trimmed.contains(' final ') ||
        trimmed.contains(' const ')) {
      return 'dart';
    }
    return 'plain';
  }

  String _guideLine(String line, String lang) {
    // Build a mask for positions to underline.
    final mask = List<bool>.filled(line.length, false);

    void mark(RegExp re) {
      for (final m in re.allMatches(line)) {
        final start = m.start;
        final end = m.end;
        for (int i = start; i < end && i < mask.length; i++) {
          mask[i] = true;
        }
      }
    }

    switch (lang) {
      case 'dart':
        mark(RegExp(r'"[^"]*"'));
        mark(RegExp(r"'[^']*'"));
        mark(RegExp(r'\b\d+(?:\.\d+)?\b'));
        break;
      case 'json':
        mark(RegExp(r'"[^"]*"\s*:')); // keys (incl colon)
        mark(RegExp(r':\s*"[^"]*"')); // string values
        mark(RegExp(r':\s*-?\d+(?:\.\d+)?')); // numbers
        mark(RegExp(r':\s*(true|false|null)\b')); // booleans/null
        break;
      case 'shell':
        mark(RegExp(r'\s--?[A-Za-z0-9][A-Za-z0-9\-]*'));
        mark(RegExp(r'"[^"]*"'));
        mark(RegExp(r"'[^']*'"));
        mark(RegExp(r'/[^\s]+'));
        break;
    }

    if (!mask.contains(true)) return '';
    final buf = StringBuffer();
    for (int i = 0; i < mask.length; i++) {
      buf.write(mask[i] ? '^' : ' ');
    }
    return buf.toString();
  }
}

String _defaultTitle(String lang) {
  switch (lang) {
    case 'dart':
      return 'Highlight · Dart';
    case 'json':
      return 'Highlight · JSON';
    case 'shell':
      return 'Highlight · Shell';
    default:
      return 'Highlight';
  }
}

 

/// Convenience function mirroring the requested API name.
void highlight(
  String text, {
  PromptTheme theme = const PromptTheme(),
  String language = 'auto',
  String? title,
  bool color = true,
  bool guides = false,
}) {
  Highlight(
    text,
    theme: theme,
    language: language,
    title: title,
    color: color,
    guides: guides,
  ).show();
}
