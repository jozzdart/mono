import 'dart:async';
import 'dart:io';

import '../style/theme.dart';
import '../system/hints.dart';
import '../system/line_builder.dart';
import '../system/widget_frame.dart';

/// Wizard – orchestrates a sequence of prompts with auto state passing.
///
/// Design goals:
/// - Theme-aware, aligned with ThemeDemo borders, accents and layout
/// - Class-based API with clear, composable steps
/// - Auto state passing between steps (mutable state map)
/// - Flexible step result handling
///
/// **Mixins:** Implements [Themeable] for fluent theme configuration:
/// ```dart
/// final result = await Wizard(title: 'Setup', steps: steps)
///   .withPastelTheme()
///   .run();
/// ```
///
/// Typical usage:
///   final result = await Wizard(
///     title: 'Project Setup',
///     steps: [
///       WizardStep(
///         id: 'name',
///         label: 'Project Name',
///         run: (state, theme) async =>
///             await TextPrompt(prompt: 'Project name', theme: theme).run(),
///       ),
///       // ... more steps ...
///     ],
///   ).withPastelTheme().run();
///
/// The returned map contains values keyed by step `id`.
class Wizard with Themeable {
  final String title;
  final List<WizardStep> steps;
  @override
  final PromptTheme theme;
  final bool showProgress;

  Wizard({
    required this.title,
    required this.steps,
    this.theme = PromptTheme.dark,
    this.showProgress = true,
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
  Future<Map<String, dynamic>?> run() async {
    final Map<String, dynamic> state = <String, dynamic>{};

    int index = 0;
    while (index >= 0 && index < steps.length) {
      if (showProgress) _renderProgress(index, state);

      final step = steps[index];
      final result = await step.run(state, theme);

      // Interpret result
      if (result is WizardResult) {
        switch (result.flow) {
          case WizardFlow.cancel:
            return null;
          case WizardFlow.back:
            index = (index - 1).clamp(0, steps.length - 1);
            continue;
          case WizardFlow.repeat:
            continue; // rerun current step
          case WizardFlow.continueNext:
            state.addAll(result.updates);
            index++;
            continue;
        }
      }

      // Convenience: plain value → store under step id and continue
      state[step.id] = result;
      index++;
    }

    return state;
  }

  void _renderProgress(int index, Map<String, dynamic> state) {
    final lb = LineBuilder(theme);
    final frame = WidgetFrame(
      title: title,
      theme: theme,
      hintStyle: HintStyle.none, // Manual hints below
    );

    frame.show((ctx) {
      // Step header
      final stepNum = '${index + 1}/${steps.length}';
      ctx.gutterLine(
          '${theme.dim}Step${theme.reset} ${theme.accent}$stepNum${theme.reset}');

      ctx.writeConnector();

      // Steps listing
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

    // External hints (outside the frame)
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
  final FutureOr<dynamic> Function(
      Map<String, dynamic> state, PromptTheme theme) run;

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
