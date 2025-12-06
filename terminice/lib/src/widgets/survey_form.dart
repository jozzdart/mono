import '../style/theme.dart';
import '../system/focus_navigation.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/prompt_runner.dart';
import '../system/text_input_buffer.dart';

/// SurveyForm – interactive questionnaire builder.
///
/// Aligns with ThemeDemo styling:
/// - Bordered title and bottom line via FrameRenderer
/// - Left gutter uses the theme's vertical border glyph
/// - Accent/highlight colors for selections
///
/// Controls:
/// - ↑ / ↓ navigate questions
/// - ← / → change option or rating
/// - Space toggle (multi-choice)
/// - Enter next/submit
/// - Esc cancel (returns null)
enum SurveyQuestionType {
  text,
  singleChoice,
  multiChoice,
  rating,
  yesNo,
}

class SurveyQuestionSpec {
  final String name; // key in the result map
  final String prompt; // question text
  final SurveyQuestionType type;
  final List<String> options; // for single/multi choice
  final int minRating; // for rating
  final int maxRating; // for rating
  final String? placeholder; // for text
  final String initialText; // for text
  final int? initialRating; // for rating
  final int? initialChoiceIndex; // for singleChoice
  final Set<int> initialMulti; // for multiChoice
  final bool? initialYes; // for yesNo
  final String? Function(dynamic value)? validator; // optional validation

  const SurveyQuestionSpec.text({
    required this.name,
    required this.prompt,
    this.placeholder,
    this.initialText = '',
    this.validator,
  })  : type = SurveyQuestionType.text,
        options = const [],
        minRating = 1,
        maxRating = 5,
        initialRating = null,
        initialChoiceIndex = null,
        initialMulti = const <int>{},
        initialYes = null;

  const SurveyQuestionSpec.singleChoice({
    required this.name,
    required this.prompt,
    required this.options,
    this.initialChoiceIndex,
    this.validator,
  })  : type = SurveyQuestionType.singleChoice,
        placeholder = null,
        initialText = '',
        minRating = 1,
        maxRating = 5,
        initialRating = null,
        initialMulti = const <int>{},
        initialYes = null;

  const SurveyQuestionSpec.multiChoice({
    required this.name,
    required this.prompt,
    required this.options,
    Set<int>? initial,
    this.validator,
  })  : type = SurveyQuestionType.multiChoice,
        placeholder = null,
        initialText = '',
        minRating = 1,
        maxRating = 5,
        initialRating = null,
        initialChoiceIndex = null,
        initialMulti = initial ?? const <int>{},
        initialYes = null;

  const SurveyQuestionSpec.rating({
    required this.name,
    required this.prompt,
    this.minRating = 1,
    this.maxRating = 5,
    this.initialRating,
    this.validator,
  })  : type = SurveyQuestionType.rating,
        placeholder = null,
        initialText = '',
        options = const [],
        initialChoiceIndex = null,
        initialMulti = const <int>{},
        initialYes = null;

  const SurveyQuestionSpec.yesNo({
    required this.name,
    required this.prompt,
    this.initialYes,
    this.validator,
  })  : type = SurveyQuestionType.yesNo,
        placeholder = null,
        initialText = '',
        options = const [],
        minRating = 1,
        maxRating = 5,
        initialRating = null,
        initialChoiceIndex = null,
        initialMulti = const <int>{};
}

class SurveyResult {
  final Map<String, dynamic> values;
  const SurveyResult(this.values);
  dynamic operator [](String key) => values[key];
}

class SurveyForm {
  final String title;
  final List<SurveyQuestionSpec> questions;
  final PromptTheme theme;

  SurveyForm({
    required this.title,
    required this.questions,
    this.theme = PromptTheme.dark,
  }) : assert(
            questions.isNotEmpty, 'SurveyForm requires at least one question');

  /// Runs the interactive survey. Returns null if cancelled.
  SurveyResult? run() {
    final style = theme.style;

    // State per question - use centralized focus navigation
    final focus = FocusNavigation(itemCount: questions.length);
    final innerCursor = List<int>.filled(questions.length, 0);
    // Use centralized text input for text questions
    final textValues = List<TextInputBuffer>.generate(
      questions.length,
      (i) => TextInputBuffer(initialText: questions[i].initialText),
    );
    final singleValues = List<int?>.generate(
        questions.length, (i) => questions[i].initialChoiceIndex);
    final multiValues = List<Set<int>>.generate(
        questions.length, (i) => {...questions[i].initialMulti});
    final ratingValues = List<int?>.generate(
        questions.length, (i) => questions[i].initialRating);
    final yesNoValues =
        List<bool?>.generate(questions.length, (i) => questions[i].initialYes);
    bool cancelled = false;

    // Validator function for FocusNavigation
    String? validateQuestion(int index) {
      final q = questions[index];
      dynamic val;
      switch (q.type) {
        case SurveyQuestionType.text:
          val = textValues[index].text;
          break;
        case SurveyQuestionType.singleChoice:
          val = singleValues[index];
          break;
        case SurveyQuestionType.multiChoice:
          val = multiValues[index];
          break;
        case SurveyQuestionType.rating:
          val = ratingValues[index];
          break;
        case SurveyQuestionType.yesNo:
          val = yesNoValues[index];
          break;
      }
      return q.validator?.call(val);
    }

    String renderValue(int index) {
      final q = questions[index];
      switch (q.type) {
        case SurveyQuestionType.text:
          final v = textValues[index].text;
          if (v.isEmpty && (q.placeholder?.isNotEmpty ?? false)) {
            return '${theme.dim}${q.placeholder}${theme.reset}';
          }
          return '${theme.accent}$v${theme.reset}';
        case SurveyQuestionType.singleChoice:
          final sel = singleValues[index];
          final buf = StringBuffer();
          for (var i = 0; i < q.options.length; i++) {
            final isSel = sel == i;
            if (i > 0) buf.write('  ');
            final content = isSel
                ? '${theme.bold}${q.options[i]}${theme.reset}'
                : q.options[i];
            buf.write(
                isSel ? '${theme.accent}<$content>${theme.reset}' : content);
          }
          return buf.toString();
        case SurveyQuestionType.multiChoice:
          final selected = multiValues[index];
          final maxIdx = q.options.isNotEmpty ? q.options.length - 1 : 0;
          final cur = innerCursor[index].clamp(0, maxIdx);
          final buf = StringBuffer();
          for (var i = 0; i < q.options.length; i++) {
            if (i > 0) buf.write('  ');
            final isOn = selected.contains(i);
            final isCursor = i == cur;
            final sym = isOn ? style.checkboxOnSymbol : style.checkboxOffSymbol;
            final col = isOn ? theme.checkboxOn : theme.checkboxOff;
            final label = '$col$sym${theme.reset} ${q.options[i]}';
            buf.write(
                isCursor ? '${theme.inverse}$label${theme.reset}' : label);
          }
          return buf.toString();
        case SurveyQuestionType.rating:
          final minR = q.minRating;
          final maxR = q.maxRating;
          final sel = (ratingValues[index] ?? minR).clamp(minR, maxR);
          final buf = StringBuffer();
          for (var i = minR; i <= maxR; i++) {
            final ch = i <= sel ? '★' : '☆';
            final col = i <= sel ? theme.accent : theme.dim;
            buf.write('$col$ch${theme.reset} ');
          }
          buf.write('${theme.dim}($sel/$maxR)${theme.reset}');
          return buf.toString();
        case SurveyQuestionType.yesNo:
          final val = yesNoValues[index];
          final yes = val == true;
          final no = val == false;
          final yesLabel =
              yes ? '${theme.accent}${theme.bold}<Yes>${theme.reset}' : 'Yes';
          final noLabel =
              no ? '${theme.accent}${theme.bold}<No>${theme.reset}' : 'No';
          return '$yesLabel  ${theme.dim}|${theme.reset}  $noLabel';
      }
    }

    void render(RenderOutput out) {
      final frame = FramedLayout(title, theme: theme);
      final baseTitle = frame.top();
      final header = style.boldPrompt
          ? '${theme.bold}$baseTitle${theme.reset}'
          : baseTitle;
      out.writeln(header);

      if (style.showBorder) {
        out.writeln(frame.connector());
      }

      for (var i = 0; i < questions.length; i++) {
        final isFocused = focus.isFocused(i);
        final prefix = '${theme.gray}${style.borderVertical}${theme.reset} ';
        final arrow =
            isFocused ? '${theme.accent}${style.arrow}${theme.reset}' : ' ';
        final label = '${theme.selection}${questions[i].prompt}${theme.reset}';
        final value = renderValue(i);
        var line = '$arrow $label: $value';

        if (isFocused && style.useInverseHighlight) {
          out.writeln('$prefix${theme.inverse}$line${theme.reset}');
        } else {
          out.writeln('$prefix$line');
        }

        // Error line if invalid - use FocusNavigation's error tracking
        final err = focus.getError(i);
        if (err != null && err.isNotEmpty) {
          out.writeln('$prefix${theme.highlight}$err${theme.reset}');
        }
      }

      if (style.showBorder) {
        out.writeln(frame.bottom());
      }

      out.writeln(Hints.grid([
        [Hints.key('↑/↓', theme), 'navigate questions'],
        [Hints.key('←/→', theme), 'change option/rating'],
        [Hints.key('Space', theme), 'toggle (multi)'],
        [Hints.key('Enter', theme), 'next / submit'],
        [Hints.key('Esc', theme), 'cancel'],
      ], theme));
    }

    void moveInner(int delta) {
      final idx = focus.focusedIndex;
      final q = questions[idx];
      if (q.type == SurveyQuestionType.singleChoice ||
          q.type == SurveyQuestionType.multiChoice) {
        final len = q.options.length;
        if (len == 0) return;
        innerCursor[idx] = (innerCursor[idx] + delta + len) % len;
        if (q.type == SurveyQuestionType.singleChoice) {
          singleValues[idx] = innerCursor[idx];
          focus.validateOne(idx, validateQuestion);
        }
      } else if (q.type == SurveyQuestionType.rating) {
        final minR = q.minRating;
        final maxR = q.maxRating;
        final cur = (ratingValues[idx] ?? minR) + delta;
        ratingValues[idx] = cur.clamp(minR, maxR);
        focus.validateOne(idx, validateQuestion);
      } else if (q.type == SurveyQuestionType.yesNo) {
        final current = yesNoValues[idx];
        if (delta != 0) {
          if (current == null) {
            yesNoValues[idx] = delta > 0 ? true : false;
          } else {
            yesNoValues[idx] = !current;
          }
          focus.validateOne(idx, validateQuestion);
        }
      }
    }

    void toggleOrSelect() {
      final idx = focus.focusedIndex;
      final q = questions[idx];
      if (q.type == SurveyQuestionType.multiChoice) {
        final maxIdx = q.options.isNotEmpty ? q.options.length - 1 : 0;
        final cursorIdx = innerCursor[idx].clamp(0, maxIdx);
        final set = multiValues[idx];
        if (set.contains(cursorIdx)) {
          set.remove(cursorIdx);
        } else {
          set.add(cursorIdx);
        }
        focus.validateOne(idx, validateQuestion);
      } else if (q.type == SurveyQuestionType.singleChoice) {
        if (q.options.isEmpty) return;
        singleValues[idx] = innerCursor[idx].clamp(0, q.options.length - 1);
        focus.validateOne(idx, validateQuestion);
      } else if (q.type == SurveyQuestionType.yesNo) {
        yesNoValues[idx] = !(yesNoValues[idx] ?? false);
        focus.validateOne(idx, validateQuestion);
      }
    }

    void handleTextInput(KeyEvent ev) {
      final idx = focus.focusedIndex;
      final q = questions[idx];
      if (q.type != SurveyQuestionType.text) return;
      if (textValues[idx].handleKey(ev)) {
        focus.validateOne(idx, validateQuestion);
      }
    }

    // Initial validation pass and cursor sync from initial values
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      if (q.type == SurveyQuestionType.singleChoice) {
        final idx = (singleValues[i] ?? 0);
        innerCursor[i] =
            q.options.isNotEmpty ? idx.clamp(0, q.options.length - 1) : 0;
      } else if (q.type == SurveyQuestionType.multiChoice) {
        if (q.options.isNotEmpty) {
          final first = multiValues[i].isNotEmpty
              ? (multiValues[i].toList()..sort()).first
              : 0;
          innerCursor[i] = first.clamp(0, q.options.length - 1);
        }
      }
    }
    // Initial validation using FocusNavigation
    focus.validateAll(validateQuestion, focusFirstInvalid: false);

    final runner = PromptRunner(hideCursor: true);
    final result = runner.run(
      render: render,
      onKey: (ev) {
        if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
          cancelled = true;
          return PromptResult.cancelled;
        }

        if (ev.type == KeyEventType.enter) {
          // If not last, advance; otherwise submit if valid
          if (focus.focusedIndex < questions.length - 1) {
            focus.moveDown();
          } else {
            // Use FocusNavigation's validateAll with focusFirstInvalid
            if (focus.validateAll(validateQuestion, focusFirstInvalid: true)) {
              return PromptResult.confirmed;
            }
          }
        } else if (ev.type == KeyEventType.arrowUp) {
          focus.moveUp();
        } else if (ev.type == KeyEventType.arrowDown ||
            ev.type == KeyEventType.tab) {
          focus.moveDown();
        } else if (ev.type == KeyEventType.arrowLeft) {
          moveInner(-1);
        } else if (ev.type == KeyEventType.arrowRight) {
          moveInner(1);
        } else if (ev.type == KeyEventType.space) {
          toggleOrSelect();
        } else {
          // Text input (typing, backspace) - handled by centralized TextInputBuffer
          handleTextInput(ev);
        }

        return null;
      },
    );

    if (cancelled || result == PromptResult.cancelled) return null;
    final out = <String, dynamic>{};
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      switch (q.type) {
        case SurveyQuestionType.text:
          out[q.name] = textValues[i].text;
          break;
        case SurveyQuestionType.singleChoice:
          final idx = singleValues[i];
          out[q.name] = idx == null || idx < 0 || idx >= q.options.length
              ? null
              : q.options[idx];
          break;
        case SurveyQuestionType.multiChoice:
          final indices = multiValues[i].toList()..sort();
          out[q.name] =
              indices.map((j) => q.options[j]).toList(growable: false);
          break;
        case SurveyQuestionType.rating:
          out[q.name] = ratingValues[i];
          break;
        case SurveyQuestionType.yesNo:
          out[q.name] = yesNoValues[i];
          break;
      }
    }
    return SurveyResult(out);
  }
}

/// Convenience runner
SurveyResult? surveyForm({
  required String title,
  required List<SurveyQuestionSpec> questions,
  PromptTheme theme = PromptTheme.dark,
}) =>
    SurveyForm(title: title, questions: questions, theme: theme).run();
