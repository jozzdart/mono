import 'dart:io';

import '../style/theme.dart';
import '../system/frame_renderer.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/terminal.dart';

/// TutorialRunner – interactive tutorial that tracks progress.
///
/// Aligns with ThemeDemo styling:
/// - Themed title bar and bottom border
/// - Left gutter uses the theme's vertical border glyph
/// - Accent/highlight colors for emphasis, subtle dimming for context
///
/// Controls:
/// - ↑ / ↓ navigate between steps
/// - Space toggles done for the focused step
/// - R resets all progress
/// - Enter confirms (returns updated steps)
/// - Esc / Ctrl+C cancels (returns original steps)
class TutorialRunner {
  final String title;
  final List<TutorialStep> steps;
  final PromptTheme theme;
  final bool useTerminalWidth;

  TutorialRunner({
    this.title = 'Tutorial Runner',
    required this.steps,
    this.theme = PromptTheme.dark,
    this.useTerminalWidth = true,
  }) : assert(steps.length > 0);

  /// Runs the tutorial. Returns the final list of steps (possibly updated).
  /// If cancelled, returns the original list unchanged.
  List<TutorialStep> run() {
    if (steps.isEmpty) return steps;

    final style = theme.style;
    int focused = 0;
    bool cancelled = false;
    var current = List<TutorialStep>.from(steps);
    final initial = List<TutorialStep>.from(steps);

    int _terminalColumns() {
      try {
        if (stdout.hasTerminal) return stdout.terminalColumns;
      } catch (_) {}
      return 80;
    }

    ({int content, int titleWidth, int descWidth}) _layout() {
      final termCols = useTerminalWidth ? _terminalColumns() : 80;
      final content = (termCols - 4).clamp(48, 200);
      // Columns: [arrow][checkbox] [title]
      final titleWidth = (content - 6).clamp(16, content);
      // Description is shown on its own indented line; subtract a bit more for indent and bullets
      final descWidth = (content - 8).clamp(16, content);
      return (content: content, titleWidth: titleWidth, descWidth: descWidth);
    }

    String _checkbox(bool done, {bool highlight = false}) {
      final sym = done ? style.checkboxOnSymbol : style.checkboxOffSymbol;
      final color = done ? theme.checkboxOn : theme.checkboxOff;
      final out = '$color$sym${theme.reset}';
      if (highlight && style.useInverseHighlight) return '${theme.inverse}$out${theme.reset}';
      return out;
    }

    int _doneCount() => current.where((s) => s.done).length;

    String _progressBar(int done, int total, {int width = 28}) {
      if (total <= 0) return '';
      final ratio = (done / total).clamp(0, 1.0);
      final filled = (ratio * width).round();
      final bar = '${'█' * filled}${'░' * (width - filled)}';
      return '${theme.accent}$bar${theme.reset}';
    }

    String _truncate(String text, int max) {
      if (text.length <= max) return text;
      if (max <= 1) return text.substring(0, max);
      return text.substring(0, max - 1) + '…';
    }

    List<String> _wrap(String text, int width) {
      if (text.trim().isEmpty) return const [];
      final words = text.split(RegExp(r'\s+'));
      final lines = <String>[];
      var line = StringBuffer();
      for (final w in words) {
        if (line.isEmpty) {
          line.write(w);
          continue;
        }
        final proposed = line.toString().length + 1 + w.length;
        if (proposed > width) {
          lines.add(line.toString());
          line = StringBuffer(w);
        } else {
          line.write(' ');
          line.write(w);
        }
      }
      if (!line.isEmpty) lines.add(line.toString());
      return lines;
    }

    void _toggleDone(int i) {
      final s = current[i];
      current[i] = s.copyWith(done: !s.done);
    }

    void _resetAll() {
      for (var i = 0; i < current.length; i++) {
        final s = current[i];
        if (s.done) current[i] = s.copyWith(done: false);
      }
    }

    void render() {
      Terminal.clearAndHome();

      // Title
      final top = style.showBorder
          ? FrameRenderer.titleWithBorders(title, theme)
          : FrameRenderer.plainTitle(title, theme);
      stdout.writeln(style.boldPrompt ? '${theme.bold}$top${theme.reset}' : top);

      final l = _layout();

      // Optional connector
      if (style.showBorder) {
        stdout.writeln(FrameRenderer.connectorLine(title, theme));
      }

      // Progress section
      final done = _doneCount();
      final total = current.length;
      final pct = total == 0 ? 0 : ((done / total) * 100).round();
      final leftPrefix = '${theme.gray}${style.borderVertical}${theme.reset} ';
      stdout.writeln('$leftPrefix${theme.dim}Progress${theme.reset} ${theme.accent}$done${theme.reset}/${theme.accent}$total${theme.reset} (${theme.highlight}$pct%${theme.reset})');
      stdout.writeln('$leftPrefix${_progressBar(done, total, width: 28)}');

      // Underline-like connector sized to content
      stdout.writeln(
          '${theme.gray}${style.borderConnector}${'─' * (l.content)}${theme.reset}');

      // Steps list
      for (var i = 0; i < current.length; i++) {
        final isFocused = i == focused;
        final s = current[i];
        final arrow = isFocused ? '${theme.accent}${style.arrow}${theme.reset}' : ' ';
        final cb = _checkbox(s.done, highlight: isFocused);
        final titleTxt = _truncate(s.title, l.titleWidth).padRight(l.titleWidth);

        final line = StringBuffer();
        line.write(leftPrefix);
        line.write('$arrow $cb ');
        line.write(titleTxt);
        stdout.writeln(line.toString());

        if (isFocused && s.description.trim().isNotEmpty) {
          final wrapped = _wrap(s.description, l.descWidth);
          for (final w in wrapped) {
            stdout.writeln('$leftPrefix  ${theme.dim}$w${theme.reset}');
          }
        }
      }

      // Bottom
      if (style.showBorder) {
        stdout.writeln(FrameRenderer.bottomLine(title, theme));
      }

      // Hints
      stdout.writeln(Hints.grid([
        [Hints.key('↑/↓', theme), 'navigate'],
        [Hints.key('Space', theme), 'toggle done'],
        [Hints.key('R', theme), 'reset progress'],
        [Hints.key('Enter', theme), 'confirm'],
        [Hints.key('Esc', theme), 'cancel'],
      ], theme));

      Terminal.hideCursor();
    }

    int _moveUp(int i) => (i - 1 + current.length) % current.length;
    int _moveDown(int i) => (i + 1) % current.length;

    final term = Terminal.enterRaw();
    void cleanup() {
      term.restore();
      Terminal.showCursor();
    }

    render();
    try {
      while (true) {
        final ev = KeyEventReader.read();

        if (ev.type == KeyEventType.enter) break;
        if (ev.type == KeyEventType.ctrlC || ev.type == KeyEventType.esc) {
          cancelled = true;
          break;
        }

        if (ev.type == KeyEventType.arrowUp) {
          focused = _moveUp(focused);
        } else if (ev.type == KeyEventType.arrowDown) {
          focused = _moveDown(focused);
        } else if (ev.type == KeyEventType.space) {
          _toggleDone(focused);
        } else if (ev.type == KeyEventType.ctrlR ||
            (ev.type == KeyEventType.char && ev.char?.toLowerCase() == 'r')) {
          _resetAll();
        }

        render();
      }
    } finally {
      cleanup();
    }

    Terminal.clearAndHome();
    return cancelled ? initial : current;
  }
}

class TutorialStep {
  final String title;
  final String description;
  final bool done;

  const TutorialStep({
    required this.title,
    this.description = '',
    this.done = false,
  });

  TutorialStep copyWith({String? title, String? description, bool? done}) {
    return TutorialStep(
      title: title ?? this.title,
      description: description ?? this.description,
      done: done ?? this.done,
    );
  }
}


