import '../style/theme.dart';
import '../system/focus_navigation.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/prompt_runner.dart';
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
  }) : assert(steps.isNotEmpty);

  /// Runs the tutorial. Returns the final list of steps (possibly updated).
  /// If cancelled, returns the original list unchanged.
  List<TutorialStep> run() {
    if (steps.isEmpty) return steps;

    final style = theme.style;
    // Use centralized focus navigation
    final focus = FocusNavigation(itemCount: steps.length);
    bool cancelled = false;
    var current = List<TutorialStep>.from(steps);
    final initial = List<TutorialStep>.from(steps);

    ({int content, int titleWidth, int descWidth}) layout() {
      final termCols = useTerminalWidth ? TerminalInfo.columns : 80;
      final content = (termCols - 4).clamp(48, 200);
      // Columns: [arrow][checkbox] [title]
      final titleWidth = (content - 6).clamp(16, content);
      // Description is shown on its own indented line; subtract a bit more for indent and bullets
      final descWidth = (content - 8).clamp(16, content);
      return (content: content, titleWidth: titleWidth, descWidth: descWidth);
    }

    String checkbox(bool done, {bool highlight = false}) {
      final sym = done ? style.checkboxOnSymbol : style.checkboxOffSymbol;
      final color = done ? theme.checkboxOn : theme.checkboxOff;
      final out = '$color$sym${theme.reset}';
      if (highlight && style.useInverseHighlight) return '${theme.inverse}$out${theme.reset}';
      return out;
    }

    int doneCount() => current.where((s) => s.done).length;

    String progressBar(int done, int total, {int width = 28}) {
      if (total <= 0) return '';
      final ratio = (done / total).clamp(0, 1.0);
      final filled = (ratio * width).round();
      final bar = '${'█' * filled}${'░' * (width - filled)}';
      return '${theme.accent}$bar${theme.reset}';
    }

    String truncate(String text, int max) {
      if (text.length <= max) return text;
      if (max <= 1) return text.substring(0, max);
      return '${text.substring(0, max - 1)}…';
    }

    List<String> wrap(String text, int width) {
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
      if (line.isNotEmpty) lines.add(line.toString());
      return lines;
    }

    void toggleDone(int i) {
      final s = current[i];
      current[i] = s.copyWith(done: !s.done);
    }

    void resetAll() {
      for (var i = 0; i < current.length; i++) {
        final s = current[i];
        if (s.done) current[i] = s.copyWith(done: false);
      }
    }

    void render(RenderOutput out) {
      // Title
      final frame = FramedLayout(title, theme: theme);
      final top = frame.top();
      out.writeln(style.boldPrompt ? '${theme.bold}$top${theme.reset}' : top);

      final l = layout();

      // Optional connector
      if (style.showBorder) {
        out.writeln(frame.connector());
      }

      // Progress section
      final done = doneCount();
      final total = current.length;
      final pct = total == 0 ? 0 : ((done / total) * 100).round();
      final leftPrefix = '${theme.gray}${style.borderVertical}${theme.reset} ';
      out.writeln('$leftPrefix${theme.dim}Progress${theme.reset} ${theme.accent}$done${theme.reset}/${theme.accent}$total${theme.reset} (${theme.highlight}$pct%${theme.reset})');
      out.writeln('$leftPrefix${progressBar(done, total, width: 28)}');

      // Underline-like connector sized to content
      out.writeln(
          '${theme.gray}${style.borderConnector}${'─' * (l.content)}${theme.reset}');

      // Steps list
      for (var i = 0; i < current.length; i++) {
        final isFocused = focus.isFocused(i);
        final s = current[i];
        final arrow = isFocused ? '${theme.accent}${style.arrow}${theme.reset}' : ' ';
        final cb = checkbox(s.done, highlight: isFocused);
        final titleTxt = truncate(s.title, l.titleWidth).padRight(l.titleWidth);

        final line = StringBuffer();
        line.write(leftPrefix);
        line.write('$arrow $cb ');
        line.write(titleTxt);
        out.writeln(line.toString());

        if (isFocused && s.description.trim().isNotEmpty) {
          final wrapped = wrap(s.description, l.descWidth);
          for (final w in wrapped) {
            out.writeln('$leftPrefix  ${theme.dim}$w${theme.reset}');
          }
        }
      }

      // Bottom
      if (style.showBorder) {
        out.writeln(frame.bottom());
      }

      // Hints
      out.writeln(Hints.grid([
        [Hints.key('↑/↓', theme), 'navigate'],
        [Hints.key('Space', theme), 'toggle done'],
        [Hints.key('R', theme), 'reset progress'],
        [Hints.key('Enter', theme), 'confirm'],
        [Hints.key('Esc', theme), 'cancel'],
      ], theme));
    }

    final runner = PromptRunner(hideCursor: true);
    runner.run(
      render: render,
      onKey: (ev) {
        if (ev.type == KeyEventType.enter) return PromptResult.confirmed;
        if (ev.type == KeyEventType.ctrlC || ev.type == KeyEventType.esc) {
          cancelled = true;
          return PromptResult.cancelled;
        }

        if (ev.type == KeyEventType.arrowUp) {
          focus.moveUp();
        } else if (ev.type == KeyEventType.arrowDown) {
          focus.moveDown();
        } else if (ev.type == KeyEventType.space) {
          toggleDone(focus.focusedIndex);
        } else if (ev.type == KeyEventType.ctrlR ||
            (ev.type == KeyEventType.char && ev.char?.toLowerCase() == 'r')) {
          resetAll();
        }

        return null;
      },
    );

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


