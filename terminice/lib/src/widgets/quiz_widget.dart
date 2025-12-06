import 'dart:io' show stdout;

import '../style/theme.dart';
import '../system/focus_navigation.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/key_bindings.dart';
import '../system/line_builder.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

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
      // Use centralized focus navigation for option selection
      final focus = FocusNavigation(itemCount: q.options.length);

      // Use KeyBindings for declarative key handling
      final bindings = KeyBindings.verticalNavigation(
            onUp: () => focus.moveUp(),
            onDown: () => focus.moveDown(),
          ) +
          (allowNumberShortcuts
              ? KeyBindings([
                  KeyBinding.char(
                    (c) => RegExp(r'^[1-9]$').hasMatch(c),
                    (event) {
                      final ch = event.char!;
                      final idx = int.parse(ch) - 1;
                      if (idx >= 0 && idx < q.options.length) {
                        focus.jumpTo(idx);
                      }
                      return KeyActionResult.handled;
                    },
                    hintLabel: '1-9',
                    hintDescription: 'quick select',
                  ),
                ])
              : KeyBindings([])) +
          KeyBindings.confirm() +
          KeyBindings.cancel();

      // Use WidgetFrame for consistent frame rendering
      final frame = WidgetFrame(
        title: _title(qi),
        theme: theme,
        bindings: bindings,
      );

      void render(RenderOutput out) {
        frame.render(out, (ctx) {
          // Question
          ctx.boldMessage(q.text);
          if (q.description != null && q.description!.trim().isNotEmpty) {
            ctx.dimMessage(q.description!);
          }

          // Options
          for (int i = 0; i < q.options.length; i++) {
            final isSel = focus.isFocused(i);
            // Use LineBuilder for arrow (focused vs dim)
            final bullet = isSel ? ctx.lb.arrowAccent() : ctx.lb.arrowDim();
            final label = allowNumberShortcuts ? '${i + 1}. ' : '';
            final optionText = '$label${q.options[i]}';
            final line = isSel
                ? '${theme.inverse}${theme.accent} $optionText ${theme.reset}'
                : optionText;
            ctx.gutterLine('$bullet $line');
          }
        });
      }

      final runner = PromptRunner(hideCursor: true);
      final result = runner.runWithBindings(
        render: render,
        bindings: bindings,
      );

      if (result == PromptResult.cancelled) {
        earlyExit = true;
        exitedAt = qi;
        break;
      }

      selections[qi] = focus.focusedIndex;
      final isCorrect = focus.focusedIndex == q.correctIndex;
      if (isCorrect) correct++;

      if (showFeedback) {
        _renderFeedback(qi, isCorrect, q, focus.focusedIndex);
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
    // Use centralized line builder for consistent styling
    final lb = LineBuilder(theme);

    final verdict = isCorrect
        ? '${theme.info}${theme.bold}Correct!${theme.reset}'
        : '${theme.error}${theme.bold}Incorrect${theme.reset}';

    final correctAns = q.options[q.correctIndex];
    final chosen = q.options[selected];

    stdout.writeln('${lb.gutter()}$verdict');
    if (!isCorrect) {
      stdout.writeln(
          '${lb.gutter()}${theme.dim}Your answer:${theme.reset} $chosen');
      stdout.writeln(
          '${lb.gutter()}${theme.dim}Correct answer:${theme.reset} ${theme.info}$correctAns${theme.reset}');
    }

    if (style.showBorder) {
      final frame = FramedLayout(title, theme: theme);
      stdout.writeln(frame.bottom());
    }

    // Use KeyBindings for continue/skip scenario
    final continueBindings = KeyBindings.continuePrompt(
      hintDescription: 'continue / skip summary',
    );
    stdout.writeln(Hints.comma(
      continueBindings.toHintEntries().map((e) => e[1]).toList(),
      theme,
    ));

    // Wait for continue key
    continueBindings.waitForKey();
  }

  void _renderSummary(int correct) {
    final style = theme.style;
    final t = 'Quiz Summary';
    // Use centralized line builder for consistent styling
    final lb = LineBuilder(theme);
    final frame = FramedLayout(t, theme: theme);
    stdout.writeln('${theme.bold}${frame.top()}${theme.reset}');

    final total = questions.length;
    final percent = ((correct / total) * 100).clamp(0, 100).toStringAsFixed(0);
    stdout.writeln(
        '${lb.gutter()}Score: ${theme.accent}$correct${theme.reset}/${theme.bold}$total${theme.reset} (${theme.highlight}$percent%${theme.reset})');

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
