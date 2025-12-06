import 'dart:math';

import '../style/theme.dart';
import '../system/key_bindings.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

/// ConfigEditor – lightweight YAML/JSON editor with color syntax.
///
/// Aligns with ThemeDemo styling (framed header, borders, accent colors) and
/// reuses the same input model as other prompts. Designed for quick config
/// tweaks directly in the terminal.
class ConfigEditor {
  /// Title shown in the header.
  final String title;

  /// Theme to use for borders, colors and accents.
  final PromptTheme theme;

  /// Language mode: 'auto' | 'json' | 'yaml'
  final String language;

  /// Initial buffer contents.
  final String initialText;

  /// Maximum logical lines allowed in the buffer.
  final int maxLines;

  /// Number of lines rendered at once (viewport height).
  final int visibleLines;

  /// Whether an empty result is allowed when confirming.
  final bool allowEmpty;

  /// Spaces inserted for a Tab and automatic indents.
  final int tabSize;

  /// Whether to auto-indent new lines based on the previous line.
  final bool autoIndent;

  ConfigEditor({
    this.title = 'Config Editor',
    this.theme = const PromptTheme(),
    this.language = 'auto',
    this.initialText = '',
    this.maxLines = 2000,
    this.visibleLines = 14,
    this.allowEmpty = true,
    this.tabSize = 2,
    this.autoIndent = true,
  });

  /// Starts the editor. Returns the edited content as a single String.
  /// Returns empty string if cancelled.
  String run() {
    final lines = initialText.isEmpty
        ? <String>['']
        : initialText.split('\n').toList(growable: true);
    int cursorLine = 0;
    int cursorColumn = 0;
    int scrollOffset = 0;
    bool cancelled = false;

    String resolveLang() {
      if (language != 'auto') return language;
      // Auto-detect from first non-empty character across buffer
      for (final line in lines) {
        final t = line.trimLeft();
        if (t.isEmpty) continue;
        if (t.startsWith('{') || t.startsWith('[')) return 'json';
        return 'yaml';
      }
      return 'yaml';
    }

    void updateScroll() {
      if (cursorLine < scrollOffset) {
        scrollOffset = cursorLine;
      } else if (cursorLine >= scrollOffset + visibleLines) {
        scrollOffset = cursorLine - visibleLines + 1;
      }
    }

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings([
          // Confirm (Ctrl+D or Ctrl+S)
          KeyBinding.single(
            KeyEventType.ctrlD,
            (event) {
              if (allowEmpty || lines.any((l) => l.trim().isNotEmpty)) {
                return KeyActionResult.confirmed;
              }
              return KeyActionResult.handled;
            },
            hintLabel: 'Ctrl+D/S',
            hintDescription: 'confirm',
          ),
          KeyBinding.single(
            KeyEventType.ctrlGeneric,
            (event) {
              if (event.char == 's') {
                if (allowEmpty || lines.any((l) => l.trim().isNotEmpty)) {
                  return KeyActionResult.confirmed;
                }
              }
              return KeyActionResult.handled;
            },
          ),
          // Up/Down
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
          // Left/Right
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
          // Tab -> insert spaces
          KeyBinding.single(
            KeyEventType.tab,
            (event) {
              final spaces = ' ' * tabSize;
              final line = lines[cursorLine];
              final before = line.substring(0, cursorColumn);
              final after = line.substring(cursorColumn);
              lines[cursorLine] = '$before$spaces$after';
              cursorColumn += tabSize;
              return KeyActionResult.handled;
            },
            hintLabel: 'Tab',
            hintDescription: 'indent',
          ),
          // Enter – new line with optional indent carry/expand
          KeyBinding.single(
            KeyEventType.enter,
            (event) {
              if (lines.length < maxLines) {
                final line = lines[cursorLine];
                final before = line.substring(0, cursorColumn);
                final after = line.substring(cursorColumn);
                final indent = autoIndent ? _indentForNextLine(before) : '';
                lines[cursorLine] = before;
                lines.insert(cursorLine + 1, '$indent$after');
                cursorLine++;
                cursorColumn = indent.length;
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
          // Type
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
        ]) +
        KeyBindings.cancel(onCancel: () => cancelled = true);

    void render(RenderOutput out) {
      final lang = resolveLang();
      final header = '$title · ${lang.toUpperCase()}';
      final widgetFrame = WidgetFrame(
        title: header,
        theme: theme,
        bindings: bindings,
        hintStyle: HintStyle.bullets,
      );

      widgetFrame.render(out, (ctx) {
        final start = scrollOffset;
        final end = min(scrollOffset + visibleLines, lines.length);
        for (var i = start; i < end; i++) {
          final raw = lines[i];
          final isCurrent = i == cursorLine;
          final prefix = ctx.lb.arrow(isCurrent);

          if (isCurrent) {
            final safeColumn = min(cursorColumn, raw.length);
            final before = raw.substring(0, safeColumn);
            final after = raw.substring(safeColumn);
            final cursorChar = after.isEmpty ? ' ' : after[0];
            final beforeH = _highlight(before, lang);
            final afterH = after.isEmpty ? '' : _highlight(after.substring(1), lang);
            ctx.gutterLine(
                '$prefix $beforeH${theme.inverse}$cursorChar${theme.reset}$afterH');
          } else {
            ctx.gutterLine('$prefix ${_highlight(raw, lang)}');
          }
        }

        // Fill remaining viewport lines
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

  // ---------- Syntax Highlighting ----------

  String _highlight(String input, String lang) {
    switch (lang) {
      case 'json':
        return _highlightJson(input);
      case 'yaml':
      default:
        return _highlightYaml(input);
    }
  }

  String _highlightJson(String line) {
    var out = line;

    // Non-standard comments: // or #
    final slIdx = out.indexOf('//');
    final hashIdx = out.indexOf('#');
    int cut = -1;
    if (slIdx >= 0) cut = slIdx;
    if (hashIdx >= 0 && (cut == -1 || hashIdx < cut)) cut = hashIdx;
    String? comment;
    if (cut >= 0) {
      comment = out.substring(cut);
      out = out.substring(0, cut);
    }

    // Keys: "key":
    out = out.replaceAllMapped(
      RegExp(r'(\")[^\"]*(\"\s*:)'),
      (m) {
        final all = m.group(0)!;
        final parts = RegExp(r'^(\")(.*?)(\"\s*:)').firstMatch(all)!;
        return '${parts.group(1)}${theme.accent}${theme.bold}${parts.group(2)}${theme.reset}${parts.group(3)}';
      },
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

    // Punctuation (avoid breaking ANSI sequences like \x1B[95m)
    // 1) braces, comma, colon
    out = out.replaceAllMapped(
      RegExp(r'[\{\}\,\:]'),
      (m) => '${theme.dim}${m[0]}${theme.reset}',
    );
    // 2) left bracket NOT preceded by ESC
    out = out.replaceAllMapped(
      RegExp('(?<!\x1B)\\['),
      (m) => '${theme.dim}[${theme.reset}',
    );
    // 3) right bracket (safe)
    out = out.replaceAllMapped(
      RegExp(r'\]'),
      (m) => '${theme.dim}]${theme.reset}',
    );

    if (comment != null) {
      out = '$out ${theme.gray}$comment${theme.reset}';
    }
    return out;
  }

  String _highlightYaml(String line) {
    var out = line;

    // Comments
    final hash = out.indexOf('#');
    String? comment;
    if (hash == 0) return '${theme.gray}$out${theme.reset}';
    if (hash > 0) {
      comment = out.substring(hash);
      out = out.substring(0, hash);
    }

    // Keys: start-of-line or after indent: key:
    out = out.replaceAllMapped(
      RegExp(r'^(\s*)([A-Za-z0-9_\-\.]+)(\s*:)'),
      (m) => '${m[1]}${theme.accent}${theme.bold}${m[2]}${theme.reset}${theme.dim}${m[3]}${theme.reset}',
    );

    // Anchors (&name) and aliases (*name)
    out = out.replaceAllMapped(
      RegExp(r'([\s\:\[\{\,]|^)([&\*][A-Za-z0-9_\-]+)'),
      (m) => '${m[1]}${theme.selection}${m[2]}${theme.reset}',
    );

    // Quoted strings
    out = out.replaceAllMapped(
      RegExp(r"""("[^"]*"|'[^']*')"""),
      (m) => '${theme.highlight}${m[1]}${theme.reset}',
    );

    // Numbers, booleans, null (after colon or list dash)
    out = out.replaceAllMapped(
      RegExp(r'(:\s*|^-\s*)(-?\d+(?:\.\d+)?|true|false|null)\b'),
      (m) => '${m[1]}${theme.selection}${m[2]}${theme.reset}',
    );

    // Unquoted scalar value after colon
    out = out.replaceAllMapped(
      RegExp(r'(:\s*)([^#\s][^#]*)$'),
      (m) => '${m[1]}${theme.highlight}${m[2]}${theme.reset}',
    );

    // Punctuation and list dash (avoid breaking ANSI sequences)
    // 1) braces, comma, colon
    out = out.replaceAllMapped(
      RegExp(r'[\{\}\,\:]'),
      (m) => '${theme.dim}${m[0]}${theme.reset}',
    );
    // 2) left bracket NOT preceded by ESC
    out = out.replaceAllMapped(
      RegExp('(?<!\x1B)\\['),
      (m) => '${theme.dim}[${theme.reset}',
    );
    // 3) right bracket
    out = out.replaceAllMapped(
      RegExp(r'\]'),
      (m) => '${theme.dim}]${theme.reset}',
    );
    out = out.replaceAllMapped(
      RegExp(r'(^\s*)(-)\s'),
      (m) => '${m[1]}${theme.dim}${m[2]}${theme.reset} ',
    );

    if (comment != null) {
      out = '$out ${theme.gray}$comment${theme.reset}';
    }
    return out;
  }

  String _indentForNextLine(String before) {
    final baseIndent = before.length - before.trimLeft().length;
    final trimmed = before.trimRight();
    int extra = 0;
    if (trimmed.endsWith(':') || trimmed.endsWith('{') || trimmed.endsWith('[')) {
      extra = tabSize;
    }
    return ' ' * (baseIndent + extra);
  }
}


