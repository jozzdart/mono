import 'dart:io';

import '../style/theme.dart';
import '../system/frame_renderer.dart';
import '../system/hints.dart';
import '../system/key_events.dart';
import '../system/terminal.dart';

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
  }) : assert(questions.isNotEmpty, 'SurveyForm requires at least one question');

  /// Runs the interactive survey. Returns null if cancelled.
  SurveyResult? run() {
    final style = theme.style;

    // State per question
    int focused = 0;
    final innerCursor = List<int>.filled(questions.length, 0);
    final textValues = List<String>.generate(questions.length, (i) => questions[i].initialText);
    final singleValues = List<int?>.generate(questions.length, (i) => questions[i].initialChoiceIndex);
    final multiValues = List<Set<int>>.generate(questions.length, (i) => {...questions[i].initialMulti});
    final ratingValues = List<int?>.generate(questions.length, (i) => questions[i].initialRating);
    final yesNoValues = List<bool?>.generate(questions.length, (i) => questions[i].initialYes);
    final errors = List<String?>.filled(questions.length, null);
    bool cancelled = false;

    void validate(int index) {
      final q = questions[index];
      dynamic val;
      switch (q.type) {
        case SurveyQuestionType.text:
          val = textValues[index];
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
      if (q.validator != null) {
        errors[index] = q.validator!(val);
      } else {
        errors[index] = null;
      }
    }

    bool validateAll() {
      int? firstInvalid;
      for (var i = 0; i < questions.length; i++) {
        validate(i);
        if (errors[i] != null && errors[i]!.isNotEmpty && firstInvalid == null) {
          firstInvalid = i;
        }
      }
      if (firstInvalid != null) focused = firstInvalid;
      return firstInvalid == null;
    }

    String _renderValue(int index) {
      final q = questions[index];
      switch (q.type) {
        case SurveyQuestionType.text:
          final v = textValues[index];
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
            final content = isSel ? '${theme.bold}${q.options[i]}${theme.reset}' : q.options[i];
            buf.write(isSel ? '${theme.accent}<$content>${theme.reset}' : content);
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
            buf.write(isCursor ? '${theme.inverse}$label${theme.reset}' : label);
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
          final yesLabel = yes ? '${theme.accent}${theme.bold}<Yes>${theme.reset}' : 'Yes';
          final noLabel = no ? '${theme.accent}${theme.bold}<No>${theme.reset}' : 'No';
          return '$yesLabel  ${theme.dim}|${theme.reset}  $noLabel';
      }
    }

    void render() {
      Terminal.clearAndHome();

      final baseTitle = style.showBorder
          ? FrameRenderer.titleWithBorders(title, theme)
          : FrameRenderer.plainTitle(title, theme);
      final header = style.boldPrompt ? '${theme.bold}$baseTitle${theme.reset}' : baseTitle;
      stdout.writeln(header);

      if (style.showBorder) {
        stdout.writeln(FrameRenderer.connectorLine(title, theme));
      }

      for (var i = 0; i < questions.length; i++) {
        final isFocused = i == focused;
        final prefix = '${theme.gray}${style.borderVertical}${theme.reset} ';
        final arrow = isFocused ? '${theme.accent}${style.arrow}${theme.reset}' : ' ';
        final label = '${theme.selection}${questions[i].prompt}${theme.reset}';
        final value = _renderValue(i);
        var line = '$arrow $label: $value';

        if (isFocused && style.useInverseHighlight) {
          stdout.writeln('$prefix${theme.inverse}$line${theme.reset}');
        } else {
          stdout.writeln('$prefix$line');
        }

        // Error line if invalid
        final err = errors[i];
        if (err != null && err.isNotEmpty) {
          stdout.writeln('$prefix${theme.highlight}$err${theme.reset}');
        }
      }

      if (style.showBorder) {
        stdout.writeln(FrameRenderer.bottomLine(title, theme));
      }

      stdout.writeln(Hints.grid([
        [Hints.key('↑/↓', theme), 'navigate questions'],
        [Hints.key('←/→', theme), 'change option/rating'],
        [Hints.key('Space', theme), 'toggle (multi)'],
        [Hints.key('Enter', theme), 'next / submit'],
        [Hints.key('Esc', theme), 'cancel'],
      ], theme));

      Terminal.hideCursor();
    }

    void moveFocus(int delta) {
      final len = questions.length;
      focused = (focused + delta + len) % len;
    }

    void moveInner(int delta) {
      final q = questions[focused];
      if (q.type == SurveyQuestionType.singleChoice || q.type == SurveyQuestionType.multiChoice) {
        final len = q.options.length;
        if (len == 0) return;
        innerCursor[focused] = (innerCursor[focused] + delta + len) % len;
        if (q.type == SurveyQuestionType.singleChoice) {
          singleValues[focused] = innerCursor[focused];
          validate(focused);
        }
      } else if (q.type == SurveyQuestionType.rating) {
        final minR = q.minRating;
        final maxR = q.maxRating;
        final cur = (ratingValues[focused] ?? minR) + delta;
        ratingValues[focused] = cur.clamp(minR, maxR);
        validate(focused);
      } else if (q.type == SurveyQuestionType.yesNo) {
        final current = yesNoValues[focused];
        if (delta != 0) {
          if (current == null) {
            yesNoValues[focused] = delta > 0 ? true : false;
          } else {
            yesNoValues[focused] = !current;
          }
          validate(focused);
        }
      }
    }

    void toggleOrSelect() {
      final q = questions[focused];
      if (q.type == SurveyQuestionType.multiChoice) {
        final maxIdx = q.options.isNotEmpty ? q.options.length - 1 : 0;
        final idx = innerCursor[focused].clamp(0, maxIdx);
        final set = multiValues[focused];
        if (set.contains(idx)) {
          set.remove(idx);
        } else {
          set.add(idx);
        }
        validate(focused);
      } else if (q.type == SurveyQuestionType.singleChoice) {
        if (q.options.isEmpty) return;
        singleValues[focused] = innerCursor[focused].clamp(0, q.options.length - 1);
        validate(focused);
      } else if (q.type == SurveyQuestionType.yesNo) {
        yesNoValues[focused] = !(yesNoValues[focused] ?? false);
        validate(focused);
      }
    }

    void backspace() {
      final q = questions[focused];
      if (q.type != SurveyQuestionType.text) return;
      final curr = textValues[focused];
      if (curr.isEmpty) return;
      textValues[focused] = curr.substring(0, curr.length - 1);
      validate(focused);
    }

    void appendChar(String ch) {
      final q = questions[focused];
      if (q.type != SurveyQuestionType.text) return;
      textValues[focused] = textValues[focused] + ch;
      validate(focused);
    }

    // Setup terminal
    final term = Terminal.enterRaw();
    void cleanup() {
      term.restore();
      Terminal.showCursor();
    }

    // Initial validation pass and cursor sync from initial values
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      if (q.type == SurveyQuestionType.singleChoice) {
        final idx = (singleValues[i] ?? 0);
        innerCursor[i] = q.options.isNotEmpty ? idx.clamp(0, q.options.length - 1) : 0;
      } else if (q.type == SurveyQuestionType.multiChoice) {
        if (q.options.isNotEmpty) {
          final first = multiValues[i].isNotEmpty
              ? (multiValues[i].toList()..sort()).first
              : 0;
          innerCursor[i] = first.clamp(0, q.options.length - 1);
        }
      }
      validate(i);
    }

    render();

    try {
      while (true) {
        final ev = KeyEventReader.read();

        if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
          cancelled = true;
          break;
        }

        if (ev.type == KeyEventType.enter) {
          // If not last, advance; otherwise submit if valid
          if (focused < questions.length - 1) {
            moveFocus(1);
          } else {
            if (validateAll()) break;
          }
        } else if (ev.type == KeyEventType.arrowUp) {
          moveFocus(-1);
        } else if (ev.type == KeyEventType.arrowDown || ev.type == KeyEventType.tab) {
          moveFocus(1);
        } else if (ev.type == KeyEventType.arrowLeft) {
          moveInner(-1);
        } else if (ev.type == KeyEventType.arrowRight) {
          moveInner(1);
        } else if (ev.type == KeyEventType.space) {
          toggleOrSelect();
        } else if (ev.type == KeyEventType.backspace) {
          backspace();
        } else if (ev.type == KeyEventType.char && ev.char != null) {
          appendChar(ev.char!);
        }

        render();
      }
    } finally {
      cleanup();
    }

    Terminal.clearAndHome();
    if (cancelled) return null;
    final out = <String, dynamic>{};
    for (var i = 0; i < questions.length; i++) {
      final q = questions[i];
      switch (q.type) {
        case SurveyQuestionType.text:
          out[q.name] = textValues[i];
          break;
        case SurveyQuestionType.singleChoice:
          final idx = singleValues[i];
          out[q.name] = idx == null || idx < 0 || idx >= q.options.length
              ? null
              : q.options[idx];
          break;
        case SurveyQuestionType.multiChoice:
          final indices = multiValues[i].toList()..sort();
          out[q.name] = indices.map((j) => q.options[j]).toList(growable: false);
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


