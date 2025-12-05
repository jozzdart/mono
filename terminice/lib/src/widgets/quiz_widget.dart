import 'dart:io' show stdout;

import '../style/theme.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/prompt_runner.dart';

/// QuizWidget – question/answer interaction with scoring.
///
/// Aligns with ThemeDemo styling:
/// - Themed title bar and bottom border
/// - Left gutter uses the theme's vertical border glyph
/// - Tasteful use of accent/info/warn/error colors
class QuizWidget {
  final String title;
  final List<QuizQuestion> questions;
  final PromptTheme theme;
  final bool showFeedback; // show per-question correctness feedback
  final bool allowNumberShortcuts; // 1-9 to choose options quickly

  QuizWidget({
    required this.title,
    required this.questions,
    this.theme = const PromptTheme(),
    this.showFeedback = true,
    this.allowNumberShortcuts = true,
  }) : assert(questions.isNotEmpty, 'Provide at least one question');

  QuizResult run() {
    int correct = 0;
    final selections = <int, int>{};
    bool earlyExit = false;
    int exitedAt = 0;

    for (int qi = 0; qi < questions.length; qi++) {
      final q = questions[qi];
      int selected = 0;

      void render(RenderOutput out) {
        final style = theme.style;

        final label = _title(qi);
        final frame = FramedLayout(label, theme: theme);
        out.writeln('${theme.bold}${frame.top()}${theme.reset}');

        // Question
        out.writeln(
            '${theme.gray}${style.borderVertical}${theme.reset} ${theme.bold}${q.text}${theme.reset}');
        if (q.description != null && q.description!.trim().isNotEmpty) {
          out.writeln(
              '${theme.gray}${style.borderVertical}${theme.reset} ${theme.dim}${q.description}${theme.reset}');
        }

        // Options
        for (int i = 0; i < q.options.length; i++) {
          final isSel = i == selected;
          final bullet = isSel
              ? '${theme.accent}${style.arrow}${theme.reset}'
              : '${theme.dim}${style.arrow}${theme.reset}';
          final label = allowNumberShortcuts
              ? '${i + 1}. '
              : '';
          final optionText = '$label${q.options[i]}';
          final line = isSel
              ? '${theme.inverse}${theme.accent} $optionText ${theme.reset}'
              : optionText;
          out.writeln(
              '${theme.gray}${style.borderVertical}${theme.reset} $bullet $line');
        }

        // Bottom border
        if (style.showBorder) {
          out.writeln(frame.bottom());
        }

        // Hints
        out.writeln(Hints.bullets([
          Hints.hint('↑/↓', 'navigate', theme),
          Hints.hint('Enter', 'submit', theme),
          if (allowNumberShortcuts) Hints.hint('1-9', 'quick select', theme),
          Hints.hint('Esc', 'quit', theme),
        ], theme));
      }

      final runner = PromptRunner(hideCursor: true);
      final result = runner.run(
        render: render,
        onKey: (ev) {
          if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
            return PromptResult.cancelled;
          }

          if (ev.type == KeyEventType.arrowUp) {
            selected = (selected - 1 + q.options.length) % q.options.length;
            return null;
          }

          if (ev.type == KeyEventType.arrowDown) {
            selected = (selected + 1) % q.options.length;
            return null;
          }

          if (allowNumberShortcuts && ev.type == KeyEventType.char) {
            final ch = ev.char!;
            if (RegExp(r'^[1-9]$').hasMatch(ch)) {
              final idx = int.parse(ch) - 1;
              if (idx >= 0 && idx < q.options.length) {
                selected = idx;
                return null;
              }
            }
          }

          if (ev.type == KeyEventType.enter) {
            return PromptResult.confirmed;
          }

          return null;
        },
      );

      if (result == PromptResult.cancelled) {
        earlyExit = true;
        exitedAt = qi;
        break;
      }

      selections[qi] = selected;
      final isCorrect = selected == q.correctIndex;
      if (isCorrect) correct++;

      if (showFeedback) {
        _renderFeedback(qi, isCorrect, q, selected);
      }
    }

    if (earlyExit) {
      return QuizResult(
        total: questions.length,
        answered: exitedAt,
        correct: correct,
        selections: selections,
      );
    }

    // Final summary
    _renderSummary(correct);

    return QuizResult(
      total: questions.length,
      answered: questions.length,
      correct: correct,
      selections: selections,
    );
  }

  void _renderFeedback(int qi, bool isCorrect, QuizQuestion q, int selected) {
    final style = theme.style;
    final title = _title(qi);

    final verdict = isCorrect
        ? '${theme.info}${theme.bold}Correct!${theme.reset}'
        : '${theme.error}${theme.bold}Incorrect${theme.reset}';

    final correctAns = q.options[q.correctIndex];
    final chosen = q.options[selected];

    stdout.writeln(
        '${theme.gray}${style.borderVertical}${theme.reset} $verdict');
    if (!isCorrect) {
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} ${theme.dim}Your answer:${theme.reset} $chosen');
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} ${theme.dim}Correct answer:${theme.reset} ${theme.info}$correctAns${theme.reset}');
    }

    if (style.showBorder) {
      final frame = FramedLayout(title, theme: theme);
      stdout.writeln(frame.bottom());
    }

    stdout.writeln(Hints.comma([
      'Press Enter to continue',
      'Esc to skip summary',
    ], theme));

    // Wait for Enter or Esc before continuing
    while (true) {
      final ev = KeyEventReader.read();
      if (ev.type == KeyEventType.enter) break;
      if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) break;
    }
  }

  void _renderSummary(int correct) {
    final style = theme.style;
    final t = 'Quiz Summary';
    final frame = FramedLayout(t, theme: theme);
    stdout.writeln('${theme.bold}${frame.top()}${theme.reset}');

    final total = questions.length;
    final percent = ((correct / total) * 100).clamp(0, 100).toStringAsFixed(0);
    stdout.writeln(
        '${theme.gray}${style.borderVertical}${theme.reset} Score: ${theme.accent}$correct${theme.reset}/${theme.bold}$total${theme.reset} (${theme.highlight}$percent%${theme.reset})');

    if (style.showBorder) {
      stdout.writeln(frame.bottom());
    }
  }

  String _title(int qi) {
    final n = questions.length;
    return '$title · Q${qi + 1}/$n';
  }
}

class QuizQuestion {
  final String text;
  final List<String> options;
  final int correctIndex;
  final String? description;

  QuizQuestion({
    required this.text,
    required this.options,
    required this.correctIndex,
    this.description,
  }) : assert(correctIndex >= 0 && correctIndex < options.length,
            'correctIndex must be within options');
}

class QuizResult {
  final int total;
  final int answered;
  final int correct;
  final Map<int, int> selections; // questionIndex -> selectedOptionIndex

  QuizResult({
    required this.total,
    required this.answered,
    required this.correct,
    required this.selections,
  });
}

/// Convenience function mirroring the requested API name.
QuizResult quizWidget({
  required String title,
  required List<QuizQuestion> questions,
  PromptTheme theme = const PromptTheme(),
  bool showFeedback = true,
  bool allowNumberShortcuts = true,
}) {
  return QuizWidget(
    title: title,
    questions: questions,
    theme: theme,
    showFeedback: showFeedback,
    allowNumberShortcuts: allowNumberShortcuts,
  ).run();
}


