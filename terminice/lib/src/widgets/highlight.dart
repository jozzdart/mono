import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/rendering.dart';
import '../system/prompt_runner.dart';

/// Pretty-prints text with simple syntax and color rules.
///
/// Aligns with ThemeDemo styling: titled frame, left gutter using the
/// theme's vertical border glyph, and tasteful use of accent/highlight colors.
class Highlight {
  final String text;
  final PromptTheme theme;
  final String language; // 'auto', 'dart', 'json', 'shell', 'plain'
  final String? title;
  final bool color; // enable/disable ANSI coloring entirely
  final bool guides; // draw underline guides when color is off

  Highlight(
    this.text, {
    this.theme = const PromptTheme(),
    this.language = 'auto',
    this.title,
    this.color = true,
    this.guides = false,
  });

  /// Render highlighted output within a themed frame.
  void show() {
    final out = RenderOutput();
    _render(out);
  }

  void _render(RenderOutput out) {
    final style = theme.style;
    final label = title ?? _defaultTitle(language);

    final frame = FramedLayout(label, theme: theme);
    final top = frame.top();
    if (color) {
      out.writeln('${theme.bold}$top${theme.reset}');
    } else {
      out.writeln(stripAnsi(top));
    }

    for (final line in text.split('\n')) {
      final lang = _resolveLanguage(line);
      final colored = color ? _highlightLine(line, lang) : line;
      if (color) {
        out.writeln('${theme.gray}${style.borderVertical}${theme.reset} $colored');
      } else {
        out.writeln('${style.borderVertical} $colored');
        if (guides) {
          final guide = _guideLine(line, lang);
          if (guide.trim().isNotEmpty) {
            out.writeln('${style.borderVertical} $guide');
          }
        }
      }
    }

    if (style.showBorder) {
      final bottom = FramedLayout(label, theme: theme).bottom();
      out.writeln(color ? bottom : stripAnsi(bottom));
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

  String _highlightLine(String line, String lang) {
    switch (lang) {
      case 'dart':
        return _highlightDart(line);
      case 'json':
        return _highlightJson(line);
      case 'shell':
        return _highlightShell(line);
      default:
        return line;
    }
  }

  String _highlightDart(String line) {
    var out = line;

    // Line comments
    final commentIdx = out.indexOf('//');
    String? commentPart;
    if (commentIdx >= 0) {
      commentPart = out.substring(commentIdx);
      out = out.substring(0, commentIdx);
    }

    // Strings (simple, non-greedy)
    out = out.replaceAllMapped(
      RegExp(r'"[^"]*"'),
      (m) => '${theme.highlight}${m[0]}${theme.reset}',
    );
    out = out.replaceAllMapped(
      RegExp(r"'[^']*'"),
      (m) => '${theme.highlight}${m[0]}${theme.reset}',
    );

    // Numbers
    out = out.replaceAllMapped(
      RegExp(r'\b\d+(?:\.\d+)?\b'),
      (m) => '${theme.selection}${m[0]}${theme.reset}',
    );

    // Keywords
    const keywords = [
      'class', 'enum', 'import', 'as', 'show', 'hide', 'void', 'final',
      'const', 'var', 'return', 'if', 'else', 'for', 'while', 'switch',
      'case', 'break', 'continue', 'try', 'catch', 'on', 'throw', 'new',
      'this', 'super', 'extends', 'with', 'implements', 'static', 'get',
      'set', 'async', 'await', 'yield', 'true', 'false', 'null'
    ];
    final kwPattern = RegExp(r'\b(' + keywords.join('|') + r')\b');
    out = out.replaceAllMapped(
      kwPattern,
      (m) => '${theme.accent}${theme.bold}${m[0]}${theme.reset}',
    );

    // Punctuation
    out = out.replaceAllMapped(
      RegExp(r'[\[\]\{\}\(\)\,\;\:]'),
      (m) => '${theme.dim}${m[0]}${theme.reset}',
    );

    if (commentPart != null) {
      out = '$out ${theme.gray}$commentPart${theme.reset}';
    }
    return out;
  }

  String _highlightJson(String line) {
    var out = line;

    // Comments (non-standard): // or #
    final commentIdx = out.indexOf('//');
    final hashIdx = out.indexOf('#');
    int cut = -1;
    if (commentIdx >= 0) cut = commentIdx;
    if (hashIdx >= 0 && (cut == -1 || hashIdx < cut)) cut = hashIdx;
    String? commentPart;
    if (cut >= 0) {
      commentPart = out.substring(cut);
      out = out.substring(0, cut);
    }

    // Keys: "key":
    out = out.replaceAllMapped(
      RegExp(r'(\")([^\"]+)(\"\s*:)'),
      (m) => '${m[1]}${theme.accent}${theme.bold}${m[2]}${theme.reset}${m[3]}',
    );

    // String values
    out = out.replaceAllMapped(
      RegExp(r'(:\s*)(\"[^\"]*\")'),
      (m) => '${m[1]}${theme.highlight}${m[2]}${theme.reset}',
    );

    // Numbers, booleans, null
    out = out.replaceAllMapped(
      RegExp(r'(:\s*)(-?\d+(?:\.\d+)?|true|false|null)\b'),
      (m) => '${m[1]}${theme.selection}${m[2]}${theme.reset}',
    );

    // Punctuation
    out = out.replaceAllMapped(
      RegExp(r'[\[\]\{\}\,\:]'),
      (m) => '${theme.dim}${m[0]}${theme.reset}',
    );

    if (commentPart != null) {
      out = '$out ${theme.gray}$commentPart${theme.reset}';
    }
    return out;
  }

  String _highlightShell(String line) {
    var out = line;

    // Comments
    final hash = out.indexOf('#');
    String? commentPart;
    if (hash == 0) return '${theme.gray}$out${theme.reset}';
    if (hash > 0) {
      commentPart = out.substring(hash);
      out = out.substring(0, hash);
    }

    // Flags and options (-x, --long)
    out = out.replaceAllMapped(
      RegExp(r'(\s|^)(--?[A-Za-z0-9][A-Za-z0-9\-]*)'),
      (m) => '${m[1]}${theme.accent}${m[2]}${theme.reset}',
    );

    // Strings
    out = out.replaceAllMapped(
      RegExp(r'"[^"]*"'),
      (m) => '${theme.highlight}${m[0]}${theme.reset}',
    );
    out = out.replaceAllMapped(
      RegExp(r"'[^']*'"),
      (m) => '${theme.highlight}${m[0]}${theme.reset}',
    );

    // Paths
    out = out.replaceAllMapped(
      RegExp(r'(/[^\s]+)'),
      (m) => '${theme.selection}${m[1]}${theme.reset}',
    );

    if (commentPart != null) {
      out = '$out ${theme.gray}$commentPart${theme.reset}';
    }
    return out;
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
