import '../style/theme.dart';
import '../system/key_events.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';
import '../system/line_builder.dart';
import '../system/prompt_runner.dart';

/// StepperPrompt – interactive step-by-step wizard with progress display.
///
/// Controls:
/// - ← back
/// - → or Enter next
/// - Esc / Ctrl+C cancel (returns -1)
class StepperPrompt {
  final String title;
  final List<String> steps;
  final PromptTheme theme;
  final int startIndex;
  final bool showStepNumbers;

  StepperPrompt({
    required this.title,
    required this.steps,
    this.theme = PromptTheme.dark,
    this.startIndex = 0,
    this.showStepNumbers = true,
  }) : assert(steps.isNotEmpty),
       assert(startIndex >= 0);

  /// Runs the wizard. Returns the last confirmed step index (0-based),
  /// or -1 if cancelled.
  int run() {
    if (steps.isEmpty) return -1;

    final style = theme.style;
    int index = startIndex.clamp(0, steps.length - 1);
    bool cancelled = false;

    String progressBar(int current, int total, {int width = 24}) {
      if (total <= 1) return '${theme.accent}${'█' * width}${theme.reset}';
      final ratio = current / (total - 1);
      final filled = (ratio * width).clamp(0, width).round();
      final bar = '${'█' * filled}${'░' * (width - filled)}';
      return '${theme.accent}$bar${theme.reset}';
    }

    void render(RenderOutput out) {
      // Use centralized line builder for consistent styling
      final lb = LineBuilder(theme);

      // Title
      final frame = FramedLayout(title, theme: theme);
      final top = frame.top();
      out.writeln(style.boldPrompt ? '${theme.bold}$top${theme.reset}' : top);

      // Step header line - using LineBuilder's gutter
      final stepNum = '${index + 1}/${steps.length}';
      out.writeln(
          '${lb.gutter()}${theme.dim}Step${theme.reset} ${theme.accent}$stepNum${theme.reset}');

      // Connector line
      if (style.showBorder) {
        out.writeln(frame.connector());
      }

      // Progress bar
      out.writeln(
          '${lb.gutter()}${progressBar(index, steps.length, width: 28)}');

      // Steps list
      for (int i = 0; i < steps.length; i++) {
        final isDone = i < index;
        final isCurrent = i == index;
        final number = showStepNumbers ? '${i + 1}. ' : '';
        final label = '$number${steps[i]}';

        if (isCurrent) {
          // Use LineBuilder for arrow
          final line = ' ${lb.arrowAccent()} ${theme.inverse}${theme.accent} $label ${theme.reset}';
          out.writeln('${lb.gutterOnly()}$line');
        } else if (isDone) {
          // Use LineBuilder for checkbox
          final check = lb.checkbox(true);
          out.writeln(
              '${lb.gutterOnly()}  $check ${theme.accent}$label${theme.reset}');
        } else {
          // Use LineBuilder for checkbox
          final box = lb.checkbox(false);
          out.writeln(
              '${lb.gutterOnly()}  $box ${theme.dim}$label${theme.reset}');
        }
      }

      // Bottom border
      if (style.showBorder) {
        out.writeln(frame.bottom());
      }

      // Hints
      out.writeln(Hints.grid([
        [Hints.key('←', theme), 'back'],
        [Hints.key('→', theme), 'next'],
        [Hints.key('Enter', theme), index == steps.length - 1 ? 'finish' : 'next'],
        [Hints.key('Esc', theme), 'cancel'],
      ], theme));
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.run(
      render: render,
      onKey: (ev) {
        if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
          cancelled = true;
          return PromptResult.cancelled;
        }

        if (ev.type == KeyEventType.arrowLeft) {
          index = (index - 1).clamp(0, steps.length - 1);
          return null;
        }

        if (ev.type == KeyEventType.arrowRight || ev.type == KeyEventType.enter) {
          if (index == steps.length - 1) {
            return PromptResult.confirmed; // finish
          }
          index = (index + 1).clamp(0, steps.length - 1);
          return null;
        }

        return null;
      },
    );

    return (cancelled || result == PromptResult.cancelled) ? -1 : index;
  }
}
