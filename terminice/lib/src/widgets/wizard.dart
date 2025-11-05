import 'dart:async';
import 'dart:io';

import '../style/theme.dart';
import '../system/frame_renderer.dart';
import '../system/hints.dart';

/// Wizard – orchestrates a sequence of prompts with auto state passing.
///
/// Design goals:
/// - Theme-aware, aligned with ThemeDemo borders, accents and layout
/// - Class-based API with clear, composable steps
/// - Auto state passing between steps (mutable state map)
/// - Flexible step result handling
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
///     theme: PromptTheme.pastel,
///   ).run();
///
/// The returned map contains values keyed by step `id`.
class Wizard {
  final String title;
  final List<WizardStep> steps;
  final PromptTheme theme;
  final bool showProgress;

  Wizard({
    required this.title,
    required this.steps,
    this.theme = PromptTheme.dark,
    this.showProgress = true,
  }) : assert(steps.isNotEmpty, 'Wizard requires at least one step');

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
    final s = theme.style;
    final titleLine = s.showBorder
        ? FrameRenderer.titleWithBorders(title, theme)
        : FrameRenderer.plainTitle(title, theme);
    stdout.writeln('${theme.bold}$titleLine${theme.reset}');

    // Step header
    final stepNum = '${index + 1}/${steps.length}';
    stdout.writeln(
        '${theme.gray}${s.borderVertical}${theme.reset} ${theme.dim}Step${theme.reset} ${theme.accent}$stepNum${theme.reset}');

    // Optional connector
    if (s.showBorder) {
      stdout.writeln(FrameRenderer.connectorLine(title, theme));
    }

    // Steps listing
    for (int i = 0; i < steps.length; i++) {
      final isDone = i < index;
      final isCurrent = i == index;
      final step = steps[i];

      if (isCurrent) {
        final line =
            ' ${theme.accent}${s.arrow}${theme.reset} ${theme.inverse}${theme.accent} ${step.label} ${theme.reset}';
        stdout.writeln('${theme.gray}${s.borderVertical}${theme.reset}$line');
      } else if (isDone) {
        final check = '${theme.checkboxOn}${s.checkboxOnSymbol}${theme.reset}';
        final val = state.containsKey(step.id)
            ? ' ${theme.dim}(${_shortValue(state[step.id])})${theme.reset}'
            : '';
        stdout.writeln(
            '${theme.gray}${s.borderVertical}${theme.reset}  $check ${theme.accent}${step.label}${theme.reset}$val');
      } else {
        final box = '${theme.checkboxOff}${s.checkboxOffSymbol}${theme.reset}';
        stdout.writeln(
            '${theme.gray}${s.borderVertical}${theme.reset}  $box ${theme.dim}${step.label}${theme.reset}');
      }
    }

    if (s.showBorder) {
      stdout.writeln(FrameRenderer.bottomLine(title, theme));
    }

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
