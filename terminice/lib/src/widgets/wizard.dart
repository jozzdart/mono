import 'dart:io';

import 'package:terminice/terminice.dart';

/// Wizard – orchestrates a sequence of prompts with auto state passing.
///
/// **Example:**
/// ```dart
/// final result = Wizard(title: 'Setup', steps: [
///   WizardStep(
///     id: 'name',
///     label: 'Enter name',
///     run: (state, theme) => TextPrompt(prompt: 'Name', theme: theme).run(),
///   ),
/// ]).run();
/// ```
class Wizard with Themeable {
  final String title;
  final List<WizardStep> steps;
  @override
  final PromptTheme theme;
  final bool showProgress;

  /// Creates a wizard.
  Wizard({
    required this.title,
    required this.steps,
    this.showProgress = true,
    this.theme = PromptTheme.dark,
  }) : assert(steps.isNotEmpty, 'Wizard requires at least one step');

  @override
  Wizard copyWithTheme(PromptTheme theme) {
    return Wizard(
      title: title,
      steps: steps,
      theme: theme,
      showProgress: showProgress,
    );
  }

  /// Runs all steps in order. Returns a state map or null if cancelled.
  Map<String, dynamic>? run() {
    final Map<String, dynamic> state = <String, dynamic>{};

    int index = 0;
    while (index >= 0 && index < steps.length) {
      if (showProgress) _renderProgress(index, state);

      final step = steps[index];
      final result = step.run(state, theme);

      // Interpret result
      if (result is WizardResult) {
        switch (result.flow) {
          case WizardFlow.cancel:
            return null;
          case WizardFlow.back:
            index = (index - 1).clamp(0, steps.length - 1);
            continue;
          case WizardFlow.repeat:
            continue;
          case WizardFlow.continueNext:
            state.addAll(result.updates);
            index++;
            continue;
        }
      }

      // Plain value → store under step id and continue
      state[step.id] = result;
      index++;
    }

    return state;
  }

  void _renderProgress(int index, Map<String, dynamic> state) {
    final lb = LineBuilder(theme);
    final frame = FrameView(
      title: title,
      theme: theme,
      hintStyle: HintStyle.none,
    );

    frame.show((ctx) {
      final stepNum = '${index + 1}/${steps.length}';
      ctx.gutterLine(
          '${theme.dim}Step${theme.reset} ${theme.accent}$stepNum${theme.reset}');

      ctx.writeConnector();

      for (int i = 0; i < steps.length; i++) {
        final isDone = i < index;
        final isCurrent = i == index;
        final step = steps[i];

        if (isCurrent) {
          final line =
              ' ${lb.arrowAccent()} ${theme.inverse}${theme.accent} ${step.label} ${theme.reset}';
          ctx.line('${lb.gutterOnly()}$line');
        } else if (isDone) {
          final check = lb.checkbox(true);
          final val = state.containsKey(step.id)
              ? ' ${theme.dim}(${_shortValue(state[step.id])})${theme.reset}'
              : '';
          ctx.gutterLine(
              ' $check ${theme.accent}${step.label}${theme.reset}$val');
        } else {
          final box = lb.checkbox(false);
          ctx.gutterLine(' $box ${theme.dim}${step.label}${theme.reset}');
        }
      }
    });

    stdout.writeln(Hints.bullets([
      'Auto state passing',
      'Back: provide WizardResult.back()',
      'Cancel: WizardResult.cancel()'
    ], theme, dim: true));
  }

  String _shortValue(dynamic value) {
    if (value == null) return 'null';
    final s = value.toString();
    return s.length > 24 ? '${s.substring(0, 21)}…' : s;
  }
}

/// A single step in the [Wizard].
class WizardStep {
  final String id;
  final String label;
  final dynamic Function(Map<String, dynamic> state, PromptTheme theme) run;

  WizardStep({
    required this.id,
    required this.label,
    required this.run,
  });
}

/// Flow directives that a step can return to influence the wizard.
enum WizardFlow { continueNext, back, cancel, repeat }

/// Structured result that can be returned by a step to control the wizard.
class WizardResult {
  final WizardFlow flow;
  final Map<String, dynamic> updates;

  const WizardResult._(this.flow, this.updates);

  const WizardResult.continueWith(Map<String, dynamic> updates)
      : this._(WizardFlow.continueNext, updates);
  const WizardResult.back()
      : this._(WizardFlow.back, const <String, dynamic>{});
  const WizardResult.cancel()
      : this._(WizardFlow.cancel, const <String, dynamic>{});
  const WizardResult.repeat()
      : this._(WizardFlow.repeat, const <String, dynamic>{});
}
