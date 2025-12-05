import 'dart:math';

import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/prompt_runner.dart';

/// CodePlayground – mini REPL with input/output area.
///
/// Aligns with ThemeDemo styling:
/// - Titled frame using [FrameRenderer]
/// - Left gutter with themed vertical border
/// - Tasteful use of accent/highlight colors and aligned hints
///
/// Controls:
/// - Type to insert characters
/// - Tab inserts two spaces
/// - Enter inserts a new line
/// - ↑/↓ navigate lines, ←/→ move within the line
/// - Ctrl+R run snippet, append result to output
/// - Ctrl+L clear output
/// - Ctrl+D confirm/exit, Esc or Ctrl+C cancel
class CodePlayground {
  final String title;
  final PromptTheme theme;
  final int inputVisibleLines;
  final int outputVisibleLines;
  final int maxInputLines;
  final int maxOutputLines;

  /// Optional evaluator. Receives the current code and a mutable context map
  /// for state across evaluations. Should return a printable string.
  /// If null, a small expression evaluator is used.
  final String Function(String code, Map<String, dynamic> context)? evaluator;

  CodePlayground({
    this.title = 'CodePlayground · REPL',
    this.theme = PromptTheme.dark,
    this.inputVisibleLines = 10,
    this.outputVisibleLines = 10,
    this.maxInputLines = 200,
    this.maxOutputLines = 500,
    this.evaluator,
  })  : assert(inputVisibleLines >= 4),
        assert(outputVisibleLines >= 4),
        assert(maxInputLines >= inputVisibleLines),
        assert(maxOutputLines >= outputVisibleLines);

  /// Runs the interactive playground. Returns the last code snippet entered,
  /// or an empty string when cancelled.
  String run() {
    final style = theme.style;

    // Input state
    final lines = <String>[''];
    int cursorLine = 0;
    int cursorColumn = 0;
    int scrollOffset = 0;
    bool cancelled = false;

    // Output log (stores plain strings with ANSI allowed)
    final output = <String>[];

    // Evaluation context persisted across runs
    final ctx = <String, dynamic>{};

    String codeText() => lines.join('\n');

    void pushOutput(String s) {
      for (final line in s.split('\n')) {
        output.add(line);
      }
      if (output.length > maxOutputLines) {
        output.removeRange(0, output.length - maxOutputLines);
      }
    }

    void clearOutput() {
      output.clear();
    }

    void doRun() {
      final code = codeText();
      if (code.trim().isEmpty) return;

      // Echo code header
      final header =
          '${theme.accent}${theme.bold}› run${theme.reset} ${theme.dim}(${code.split('\n').first.trim()})${theme.reset}';
      pushOutput(header);

      try {
        final result = evaluator != null
            ? evaluator!(code, ctx)
            : _defaultEvaluate(code, ctx, theme);
        if (result.trim().isEmpty) {
          pushOutput('${theme.gray}— no output —${theme.reset}');
        } else {
          pushOutput('${theme.info}$result${theme.reset}');
        }
      } catch (e) {
        pushOutput('${theme.error}Error: $e${theme.reset}');
      }
    }

    void render(RenderOutput out) {
      // Header
      final frame = FramedLayout(title, theme: theme);
      final top = frame.top();
      out.writeln(style.boldPrompt ? '${theme.bold}$top${theme.reset}' : top);

      // Input section title connector
      out.writeln(
          '${theme.gray}${style.borderConnector}${theme.reset} ${theme.dim}Input${theme.reset}');

      // Visible input viewport
      final start = scrollOffset;
      final end = min(scrollOffset + inputVisibleLines, lines.length);
      for (var i = start; i < end; i++) {
        final raw = lines[i];
        final isCursorLine = i == cursorLine;
        final prefix =
            isCursorLine ? '${theme.accent}${style.arrow}${theme.reset}' : ' ';

        if (isCursorLine) {
          final safeCol = min(cursorColumn, raw.length);
          final before = raw.substring(0, safeCol);
          final after = raw.substring(safeCol);
          final cursorChar = after.isEmpty ? ' ' : after[0];
          final afterTail = after.length > 1 ? after.substring(1) : '';
          out.writeln(
              '${theme.gray}${style.borderVertical}${theme.reset} $prefix $before${theme.inverse}$cursorChar${theme.reset}$afterTail');
        } else {
          out.writeln(
              '${theme.gray}${style.borderVertical}${theme.reset} $prefix $raw');
        }
      }

      // Fill remaining input lines
      for (var i = end; i < start + inputVisibleLines; i++) {
        out.writeln(
            '${theme.gray}${style.borderVertical}${theme.reset}   ${theme.dim}~${theme.reset}');
      }

      // Output section title connector
      out.writeln(
          '${theme.gray}${style.borderConnector}${theme.reset} ${theme.dim}Output${theme.reset}');

      // Render output (tail)
      final outStart = max(0, output.length - outputVisibleLines);
      final outSlice = output.sublist(outStart);
      for (final line in outSlice) {
        out.writeln(
            '${theme.gray}${style.borderVertical}${theme.reset}   $line');
      }
      // Pad remaining rows
      for (int i = outSlice.length; i < outputVisibleLines; i++) {
        out.writeln('${theme.gray}${style.borderVertical}${theme.reset}   ');
      }

      // Bottom border
      if (style.showBorder) {
        out.writeln(frame.bottom());
      }

      // Hints
      out.writeln(Hints.grid([
        [Hints.key('Ctrl+R', theme), 'run'],
        [Hints.key('Ctrl+L', theme), 'clear output'],
        [Hints.key('Enter', theme), 'new line'],
        [Hints.key('↑/↓/←/→', theme), 'move'],
        [Hints.key('Ctrl+D', theme), 'confirm/exit'],
        [Hints.key('Esc', theme), 'cancel'],
      ], theme));
    }

    final runner = PromptRunner(hideCursor: true);
    runner.run(
      render: render,
      onKey: (ev) {
        // Cancel
        if (ev.type == KeyEventType.ctrlC || ev.type == KeyEventType.esc) {
          cancelled = true;
          return PromptResult.cancelled;
        }

        // Confirm/exit
        if (ev.type == KeyEventType.ctrlD) {
          return PromptResult.confirmed;
        }

        // Run
        if (ev.type == KeyEventType.ctrlR) {
          doRun();
          return null;
        }

        // Clear output (Ctrl+L)
        if (ev.type == KeyEventType.ctrlGeneric && ev.char == 'l') {
          clearOutput();
          return null;
        }

        // Typing
        if (ev.type == KeyEventType.char && ev.char != null) {
          final ch = ev.char!;
          final line = lines[cursorLine];
          final before = line.substring(0, cursorColumn);
          final after = line.substring(cursorColumn);
          lines[cursorLine] = '$before$ch$after';
          cursorColumn++;
        }

        // Tab → two spaces
        else if (ev.type == KeyEventType.tab) {
          final line = lines[cursorLine];
          final before = line.substring(0, cursorColumn);
          final after = line.substring(cursorColumn);
          lines[cursorLine] = '$before  $after';
          cursorColumn += 2;
        }

        // Backspace
        else if (ev.type == KeyEventType.backspace) {
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
        }

        // Enter → new line
        else if (ev.type == KeyEventType.enter) {
          if (lines.length < maxInputLines) {
            final line = lines[cursorLine];
            final before = line.substring(0, cursorColumn);
            final after = line.substring(cursorColumn);
            lines[cursorLine] = before;
            lines.insert(cursorLine + 1, after);
            cursorLine++;
            cursorColumn = 0;
          }
        }

        // Movement
        else if (ev.type == KeyEventType.arrowUp) {
          if (cursorLine > 0) cursorLine--;
          cursorColumn = min(cursorColumn, lines[cursorLine].length);
        } else if (ev.type == KeyEventType.arrowDown) {
          if (cursorLine < lines.length - 1) cursorLine++;
          cursorColumn = min(cursorColumn, lines[cursorLine].length);
        } else if (ev.type == KeyEventType.arrowLeft) {
          if (cursorColumn > 0) {
            cursorColumn--;
          } else if (cursorLine > 0) {
            cursorLine--;
            cursorColumn = lines[cursorLine].length;
          }
        } else if (ev.type == KeyEventType.arrowRight) {
          if (cursorColumn < lines[cursorLine].length) {
            cursorColumn++;
          } else if (cursorLine < lines.length - 1) {
            cursorLine++;
            cursorColumn = 0;
          }
        }

        // Scroll viewport for input
        if (cursorLine < scrollOffset) {
          scrollOffset = cursorLine;
        } else if (cursorLine >= scrollOffset + inputVisibleLines) {
          scrollOffset = cursorLine - inputVisibleLines + 1;
        }

        return null;
      },
    );

    if (cancelled) return '';
    return codeText();
  }
}

/// Default simple expression evaluator with variables and basic commands.
///
/// Supported:
/// - Arithmetic: +, -, *, /, parentheses
/// - Variables: `x = 2 + 3` then `x * 4`
/// - Commands:
///   - `:vars` list variables
///   - `:clear` no-op (handled by UI)
///   - `print(expr)` prints evaluated value
String _defaultEvaluate(
  String code,
  Map<String, dynamic> ctx,
  PromptTheme theme,
) {
  final buf = StringBuffer();

  String evalOne(String src) {
    src = src.trim();
    if (src.isEmpty) return '';
    if (src == ':vars') {
      if (ctx.isEmpty) return '(no variables)';
      final keys = ctx.keys.toList()..sort();
      return keys.map((k) => '$k = ${ctx[k]}').join('\n');
    }
    if (src.startsWith('print(') && src.endsWith(')')) {
      final inner = src.substring(6, src.length - 1);
      final v = _Expr(inner, ctx).parse();
      return '$v';
    }
    // Assignment
    final asg = RegExp(r'^[a-zA-Z_]\w*\s*=');
    if (asg.hasMatch(src)) {
      final eq = src.indexOf('=');
      final name = src.substring(0, eq).trim();
      final expr = src.substring(eq + 1);
      final v = _Expr(expr, ctx).parse();
      ctx[name] = v;
      return '$name = $v';
    }
    // Expression
    final v = _Expr(src, ctx).parse();
    return '$v';
  }

  final parts = code.split('\n');
  for (final p in parts) {
    final out = evalOne(p);
    if (out.isNotEmpty) buf.writeln(out);
  }
  return buf.toString().trimRight();
}

/// Tiny recursive-descent arithmetic parser.
class _Expr {
  final String src;
  final Map<String, dynamic> ctx;
  int i = 0;

  _Expr(this.src, this.ctx);

  double parse() {
    i = 0;
    final v = _parseExpr();
    _skipWs();
    if (i < src.length) {
      throw FormatException('Unexpected token at ${src.substring(i)}');
    }
    return v;
  }

  void _skipWs() {
    while (i < src.length && src.codeUnitAt(i) <= 32) {
      i++;
    }
  }

  double _parseExpr() {
    var v = _parseTerm();
    while (true) {
      _skipWs();
      if (_match('+')) {
        v += _parseTerm();
      } else if (_match('-')) {
        v -= _parseTerm();
      } else {
        break;
      }
    }
    return v;
  }

  double _parseTerm() {
    var v = _parseFactor();
    while (true) {
      _skipWs();
      if (_match('*')) {
        v *= _parseFactor();
      } else if (_match('/')) {
        final d = _parseFactor();
        if (d == 0) throw const FormatException('Division by zero');
        v /= d;
      } else {
        break;
      }
    }
    return v;
  }

  double _parseFactor() {
    _skipWs();
    if (_match('(')) {
      final v = _parseExpr();
      _skipWs();
      if (!_match(')')) throw const FormatException('Missing )');
      return v;
    }

    // number
    final start = i;
    while (i < src.length && _isNumChar(src[i])) {
      i++;
    }
    if (i > start) {
      return double.parse(src.substring(start, i));
    }

    // variable or unary +/−
    if (_match('+')) return _parseFactor();
    if (_match('-')) return -_parseFactor();

    if (_isIdentStart(_peek())) {
      final name = _readIdent();
      final v = ctx[name];
      if (v is num) return v.toDouble();
      throw FormatException('Unknown variable "$name"');
    }

    throw const FormatException('Expected expression');
  }

  String _peek() => i < src.length ? src[i] : '\u0000';
  bool _match(String ch) {
    if (i < src.length && src[i] == ch) {
      i++;
      return true;
    }
    return false;
  }

  bool _isNumChar(String ch) =>
      (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) || ch == '.';

  bool _isIdentStart(String ch) {
    final c = ch.codeUnitAt(0);
    return (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || ch == '_';
  }

  String _readIdent() {
    final start = i;
    while (i < src.length) {
      final c = src.codeUnitAt(i);
      final isAlpha = (c >= 65 && c <= 90) || (c >= 97 && c <= 122);
      final isNum = c >= 48 && c <= 57;
      if (!(isAlpha || isNum || src[i] == '_')) break;
      i++;
    }
    return src.substring(start, i);
  }
}
