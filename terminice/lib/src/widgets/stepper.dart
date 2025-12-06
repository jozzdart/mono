import '../style/theme.dart';
import '../system/key_bindings.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

/// StepperPrompt – interactive step-by-step wizard with progress display.
///
/// Controls:
/// - ← back
/// - → or Enter next
/// - Esc / Ctrl+C cancel (returns -1)
///
/// **Mixins:** Implements [Themeable] for fluent theme configuration:
/// ```dart
/// final step = StepperPrompt(title: 'Setup', steps: steps)
///   .withPastelTheme()
///   .run();
/// ```
class StepperPrompt with Themeable {
  final String title;
  final List<String> steps;
  @override
  final PromptTheme theme;
  final int startIndex;
  final bool showStepNumbers;

  StepperPrompt({
    required this.title,
    required this.steps,
    this.theme = PromptTheme.dark,
    this.startIndex = 0,
    this.showStepNumbers = true,
  })  : assert(steps.isNotEmpty),
        assert(startIndex >= 0);

  @override
  StepperPrompt copyWithTheme(PromptTheme theme) {
    return StepperPrompt(
      title: title,
      steps: steps,
      theme: theme,
      startIndex: startIndex,
      showStepNumbers: showStepNumbers,
    );
  }

  /// Runs the wizard. Returns the last confirmed step index (0-based),
  /// or -1 if cancelled.
  int run() {
    if (steps.isEmpty) return -1;

    int index = startIndex.clamp(0, steps.length - 1);
    bool cancelled = false;

    // Use KeyBindings for declarative key handling
    final bindings = KeyBindings([
          // Left arrow - back
          KeyBinding.single(
            KeyEventType.arrowLeft,
            (event) {
              index = (index - 1).clamp(0, steps.length - 1);
              return KeyActionResult.handled;
            },
            hintLabel: '←',
            hintDescription: 'back',
          ),
          // Right arrow - next
          KeyBinding.single(
            KeyEventType.arrowRight,
            (event) {
              if (index == steps.length - 1) {
                return KeyActionResult.confirmed;
              }
              index = (index + 1).clamp(0, steps.length - 1);
              return KeyActionResult.handled;
            },
            hintLabel: '→',
            hintDescription: 'next',
          ),
        ]) +
        KeyBindings.confirm(
          onConfirm: () {
            if (index == steps.length - 1) {
              return KeyActionResult.confirmed;
            }
            index = (index + 1).clamp(0, steps.length - 1);
            return KeyActionResult.handled;
          },
          hintDescription: 'next/finish',
        ) +
        KeyBindings.cancel(onCancel: () => cancelled = true);

    String progressBar(int current, int total, {int width = 24}) {
      if (total <= 1) return '${theme.accent}${'█' * width}${theme.reset}';
      final ratio = current / (total - 1);
      final filled = (ratio * width).clamp(0, width).round();
      final bar = '${'█' * filled}${'░' * (width - filled)}';
      return '${theme.accent}$bar${theme.reset}';
    }

    // Use WidgetFrame for consistent frame rendering
    final frame = WidgetFrame(
      title: title,
      theme: theme,
      bindings: bindings,
      showConnector: true,
      hintStyle: HintStyle.grid,
    );

    void render(RenderOutput out) {
      frame.render(out, (ctx) {
        // Step header line
        final stepNum = '${index + 1}/${steps.length}';
        ctx.gutterLine(
            '${theme.dim}Step${theme.reset} ${theme.accent}$stepNum${theme.reset}');

        // Connector line (already handled by WidgetFrame if showConnector is true)
        // But we need another one after step header
        ctx.writeConnector();

        // Progress bar
        ctx.gutterLine(progressBar(index, steps.length, width: 28));

        // Steps list
        for (int i = 0; i < steps.length; i++) {
          final isDone = i < index;
          final isCurrent = i == index;
          final number = showStepNumbers ? '${i + 1}. ' : '';
          final label = '$number${steps[i]}';

          if (isCurrent) {
            // Use LineBuilder for arrow
            final line =
                ' ${ctx.lb.arrowAccent()} ${theme.inverse}${theme.accent} $label ${theme.reset}';
            ctx.line('${ctx.lb.gutterOnly()}$line');
          } else if (isDone) {
            // Use LineBuilder for checkbox
            final check = ctx.lb.checkbox(true);
            ctx.line(
                '${ctx.lb.gutterOnly()}  $check ${theme.accent}$label${theme.reset}');
          } else {
            // Use LineBuilder for checkbox
            final box = ctx.lb.checkbox(false);
            ctx.line(
                '${ctx.lb.gutterOnly()}  $box ${theme.dim}$label${theme.reset}');
          }
        }
      });
    }

    final runner = PromptRunner(hideCursor: true);
    final result = runner.runWithBindings(
      render: render,
      bindings: bindings,
    );

    return (cancelled || result == PromptResult.cancelled) ? -1 : index;
  }
}
