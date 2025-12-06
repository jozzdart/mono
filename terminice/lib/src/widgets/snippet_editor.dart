import 'dart:math';

import '../style/theme.dart';
import '../system/key_bindings.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

/// SnippetEditor – small code editor with syntax highlighting.
///
/// Controls:
/// - Type to insert characters
/// - Tab inserts two spaces
/// - Enter inserts a new line
/// - Backspace deletes or merges lines
/// - ↑/↓ navigate lines, ←/→ move within line
/// - Ctrl+D confirm, Esc/ Ctrl+C cancel
class SnippetEditor {
  final String title;
  final String language; // 'auto', 'dart', 'json', 'shell', 'plain'
  final PromptTheme theme;
  final int maxLines;
  final int visibleLines;
  final String initialText;
  final bool allowEmpty;

  SnippetEditor({
    required this.title,
    this.language = 'auto',
    this.theme = PromptTheme.dark,
    this.maxLines = 200,
    this.visibleLines = 12,
    this.initialText = '',
    this.allowEmpty = true,
  });

  /// Runs the editor and returns the final snippet.
  /// Returns an empty string when cancelled.
  String run() {
    final lines = initialText.isEmpty ? <String>[''] : initialText.split('\n');
    int cursorLine = 0;
    int cursorColumn = 0;
    int scrollOffset = 0;
    bool cancelled = false;

    void updateScroll() {
      if (cursorLine < scrollOffset) {
        scrollOffset = cursorLine;
      } else if (cursorLine >= scrollOffset + visibleLines) {
        scrollOffset = cursorLine - visibleLines + 1;
      }
    }

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings([
          // Vertical movement
          KeyBinding.single(
            KeyEventType.arrowUp,
            (event) {
              if (cursorLine > 0) cursorLine--;
              cursorColumn = min(cursorColumn, lines[cursorLine].length);
              updateScroll();
              return KeyActionResult.handled;
            },
            hintLabel: '↑/↓',
            hintDescription: 'line',
          ),
          KeyBinding.single(
            KeyEventType.arrowDown,
            (event) {
              if (cursorLine < lines.length - 1) cursorLine++;
              cursorColumn = min(cursorColumn, lines[cursorLine].length);
              updateScroll();
              return KeyActionResult.handled;
            },
          ),
          // Horizontal movement
          KeyBinding.single(
            KeyEventType.arrowLeft,
            (event) {
              if (cursorColumn > 0) {
                cursorColumn--;
              } else if (cursorLine > 0) {
                cursorLine--;
                cursorColumn = lines[cursorLine].length;
              }
              updateScroll();
              return KeyActionResult.handled;
            },
            hintLabel: '←/→',
            hintDescription: 'move',
          ),
          KeyBinding.single(
            KeyEventType.arrowRight,
            (event) {
              if (cursorColumn < lines[cursorLine].length) {
                cursorColumn++;
              } else if (cursorLine < lines.length - 1) {
                cursorLine++;
                cursorColumn = 0;
              }
              updateScroll();
              return KeyActionResult.handled;
            },
          ),
          // Tab → two spaces
          KeyBinding.single(
            KeyEventType.tab,
            (event) {
              final line = lines[cursorLine];
              final before = line.substring(0, cursorColumn);
              final after = line.substring(cursorColumn);
              lines[cursorLine] = '$before  $after';
              cursorColumn += 2;
              return KeyActionResult.handled;
            },
            hintLabel: 'Tab',
            hintDescription: 'indent',
          ),
          // Enter → new line
          KeyBinding.single(
            KeyEventType.enter,
            (event) {
              if (lines.length < maxLines) {
                final line = lines[cursorLine];
                final before = line.substring(0, cursorColumn);
                final after = line.substring(cursorColumn);
                lines[cursorLine] = before;
                lines.insert(cursorLine + 1, after);
                cursorLine++;
                cursorColumn = 0;
              }
              updateScroll();
              return KeyActionResult.handled;
            },
            hintLabel: 'Enter',
            hintDescription: 'newline',
          ),
          // Backspace
          KeyBinding.single(
            KeyEventType.backspace,
            (event) {
              if (cursorColumn > 0) {
                final line = lines[cursorLine];
                lines[cursorLine] = line.substring(0, cursorColumn - 1) +
                    line.substring(cursorColumn);
                cursorColumn--;
              } else if (cursorLine > 0) {
                final prev = lines[cursorLine - 1];
                final current = lines.removeAt(cursorLine);
                cursorLine--;
                cursorColumn = prev.length;
                lines[cursorLine] = prev + current;
              }
              updateScroll();
              return KeyActionResult.handled;
            },
          ),
          // Typing
          KeyBinding.char(
            (c) => true,
            (event) {
              final ch = event.char!;
              final line = lines[cursorLine];
              final before = line.substring(0, cursorColumn);
              final after = line.substring(cursorColumn);
              lines[cursorLine] = '$before$ch$after';
              cursorColumn++;
              return KeyActionResult.handled;
            },
          ),
          // Ctrl+D confirm (only if allowEmpty or non-empty)
          KeyBinding.single(
            KeyEventType.ctrlD,
            (event) {
              if (allowEmpty || lines.any((l) => l.trim().isNotEmpty)) {
                return KeyActionResult.confirmed;
              }
              return KeyActionResult.handled;
            },
            hintLabel: 'Ctrl+D',
            hintDescription: 'confirm',
          ),
        ]) +
        KeyBindings.cancel(onCancel: () => cancelled = true);

    void render(RenderOutput out) {
      final widgetFrame = WidgetFrame(
        title: _titleWithLang(title),
        theme: theme,
        bindings: bindings,
        hintStyle: HintStyle.bullets,
      );

      widgetFrame.render(out, (ctx) {
        // Visible viewport
        final start = scrollOffset;
        final end = min(scrollOffset + visibleLines, lines.length);
        for (var i = start; i < end; i++) {
          final raw = lines[i];
          final isCursorLine = i == cursorLine;
          final prefix = ctx.lb.arrow(isCursorLine);

          if (isCursorLine) {
            final before = raw.substring(0, min(cursorColumn, raw.length));
            final after = raw.substring(min(cursorColumn, raw.length));
            final cursorChar = after.isEmpty ? ' ' : after[0];
            final afterTail = after.length > 1 ? after.substring(1) : '';

            final lang = _resolveLanguage(raw);
            final beforeH = _highlightLine(before, lang);
            final afterH = _highlightLine(afterTail, lang);
            final cursorCell = '${theme.inverse}$cursorChar${theme.reset}';

            ctx.gutterLine('$prefix $beforeH$cursorCell$afterH');
          } else {
            final lang = _resolveLanguage(raw);
            ctx.gutterLine('$prefix ${_highlightLine(raw, lang)}');
          }
        }

        // Fill remaining lines
        for (var i = end; i < start + visibleLines; i++) {
          ctx.line('${ctx.lb.gutterOnly()}   ${theme.dim}~${theme.reset}');
        }
      });
    }

    final runner = PromptRunner(hideCursor: true);
    runner.runWithBindings(
      render: render,
      bindings: bindings,
    );

    if (cancelled) return '';
    return lines.join('\n');
  }

  String _titleWithLang(String base) {
    final resolved = language == 'auto' ? null : language.toUpperCase();
    return resolved == null ? base : '$base · $resolved';
  }

  String _resolveLanguage(String line) {
    if (language != 'auto') return language;
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) return 'json';
    if (trimmed.startsWith('#')) return 'shell';
    if (trimmed.startsWith('import ') ||
        trimmed.contains(' void ') ||
        trimmed.contains(' class ') ||
        trimmed.contains(' final ') ||
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

    // Comments
    final commentIdx = out.indexOf('//');
    String? commentPart;
    if (commentIdx >= 0) {
      commentPart = out.substring(commentIdx);
      out = out.substring(0, commentIdx);
    }

    // Strings
    out = out.replaceAllMapped(
      RegExp(r'\"[^\"]*\"'),
      (m) => '${theme.highlight}${m[0]}${theme.reset}',
    );
    out = out.replaceAllMapped(
      RegExp(r"'[^']*'"),
      (m) => '${theme.highlight}${m[0]}${theme.reset}',
    );

    // Numbers
    out = out.replaceAllMapped(
      RegExp(r'\\b\\d+(?:\\.\\d+)?\\b'),
      (m) => '${theme.selection}${m[0]}${theme.reset}',
    );

    // Keywords
    const keywords = [
      'class',
      'enum',
      'import',
      'as',
      'show',
      'hide',
      'void',
      'final',
      'const',
      'var',
      'return',
      'if',
      'else',
      'for',
      'while',
      'switch',
      'case',
      'break',
      'continue',
      'try',
      'catch',
      'on',
      'throw',
      'new',
      'this',
      'super',
      'extends',
      'with',
      'implements',
      'static',
      'get',
      'set',
      'async',
      'await',
      'yield',
      'true',
      'false',
      'null'
    ];
    final kw = RegExp(r'\\b(' + keywords.join('|') + r')\\b');
    out = out.replaceAllMapped(
      kw,
      (m) => '${theme.accent}${theme.bold}${m[0]}${theme.reset}',
    );

    // Punctuation
    out = out.replaceAllMapped(
      RegExp(r'[\\[\\]\\{\\}\\(\\)\\,\\;\\:]'),
      (m) => '${theme.dim}${m[0]}${theme.reset}',
    );

    if (commentPart != null) {
      out = '$out ${theme.gray}$commentPart${theme.reset}';
    }
    return out;
  }

  String _highlightJson(String line) {
    var out = line;

    // Line comments (non-standard) // or #
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

    // Keys
    out = out.replaceAllMapped(
      RegExp(r'(\\\")(.*?)(\\\"\\s*:)'),
      (m) => '${m[1]}${theme.accent}${theme.bold}${m[2]}${theme.reset}${m[3]}',
    );

    // String values
    out = out.replaceAllMapped(
      RegExp(r'(:\\s*)(\\\"[^\\\"]*\\\")'),
      (m) => '${m[1]}${theme.highlight}${m[2]}${theme.reset}',
    );

    // Numbers/booleans/null
    out = out.replaceAllMapped(
      RegExp(r'(:\\s*)(-?\\d+(?:\\.\\d+)?|true|false|null)\\b'),
      (m) => '${m[1]}${theme.selection}${m[2]}${theme.reset}',
    );

    // Punctuation
    out = out.replaceAllMapped(
      RegExp(r'[\\[\\]\\{\\}\\,\\:]'),
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

    // Flags
    out = out.replaceAllMapped(
      RegExp(r'(\\s|^)(--?[A-Za-z0-9][A-Za-z0-9\\-]*)'),
      (m) => '${m[1]}${theme.accent}${m[2]}${theme.reset}',
    );

    // Strings
    out = out.replaceAllMapped(
      RegExp(r'\"[^\"]*\"'),
      (m) => '${theme.highlight}${m[0]}${theme.reset}',
    );
    out = out.replaceAllMapped(
      RegExp(r"'[^']*'"),
      (m) => '${theme.highlight}${m[0]}${theme.reset}',
    );

    // Paths
    out = out.replaceAllMapped(
      RegExp(r'(/[^^\n\s]+)'),
      (m) => '${theme.selection}${m[1]}${theme.reset}',
    );

    if (commentPart != null) {
      out = '$out ${theme.gray}$commentPart${theme.reset}';
    }
    return out;
  }
}
