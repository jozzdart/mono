import 'dart:io';

import '../style/theme.dart';
import '../system/terminal.dart';
import '../system/key_events.dart';
import '../system/framed_layout.dart';
import '../system/hints.dart';

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

    final term = Terminal.enterRaw();

    void cleanup() {
      term.restore();
      Terminal.showCursor();
    }

    String progressBar(int current, int total, {int width = 24}) {
      if (total <= 1) return '${theme.accent}${'█' * width}${theme.reset}';
      final ratio = current / (total - 1);
      final filled = (ratio * width).clamp(0, width).round();
      final bar = '${'█' * filled}${'░' * (width - filled)}';
      return '${theme.accent}$bar${theme.reset}';
    }

    void render() {
      Terminal.clearAndHome();

      // Title
      final frame = FramedLayout(title, theme: theme);
      final top = frame.top();
      stdout.writeln(style.boldPrompt ? '${theme.bold}$top${theme.reset}' : top);

      // Step header line
      final stepNum = '${index + 1}/${steps.length}';
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} ${theme.dim}Step${theme.reset} ${theme.accent}$stepNum${theme.reset}');

      // Connector line
      if (style.showBorder) {
        stdout.writeln(frame.connector());
      }

      // Progress bar
      stdout.writeln(
          '${theme.gray}${style.borderVertical}${theme.reset} ${progressBar(index, steps.length, width: 28)}');

      // Steps list
      for (int i = 0; i < steps.length; i++) {
        final isDone = i < index;
        final isCurrent = i == index;
        final number = showStepNumbers ? '${i + 1}. ' : '';
        final label = '$number${steps[i]}';

        if (isCurrent) {
          final line = ' ${theme.accent}${style.arrow}${theme.reset} ${theme.inverse}${theme.accent} $label ${theme.reset}';
          stdout.writeln('${theme.gray}${style.borderVertical}${theme.reset}$line');
        } else if (isDone) {
          final check = '${theme.checkboxOn}${style.checkboxOnSymbol}${theme.reset}';
          stdout.writeln(
              '${theme.gray}${style.borderVertical}${theme.reset}  $check ${theme.accent}$label${theme.reset}');
        } else {
          final box = '${theme.checkboxOff}${style.checkboxOffSymbol}${theme.reset}';
          stdout.writeln(
              '${theme.gray}${style.borderVertical}${theme.reset}  $box ${theme.dim}$label${theme.reset}');
        }
      }

      // Bottom border
      if (style.showBorder) {
        stdout.writeln(frame.bottom());
      }

      // Hints
      stdout.writeln(Hints.grid([
        [Hints.key('←', theme), 'back'],
        [Hints.key('→', theme), 'next'],
        [Hints.key('Enter', theme), index == steps.length - 1 ? 'finish' : 'next'],
        [Hints.key('Esc', theme), 'cancel'],
      ], theme));

      Terminal.hideCursor();
    }

    render();

    try {
      while (true) {
        final ev = KeyEventReader.read();

        if (ev.type == KeyEventType.esc || ev.type == KeyEventType.ctrlC) {
          cancelled = true;
          break;
        }

        if (ev.type == KeyEventType.arrowLeft) {
          index = (index - 1).clamp(0, steps.length - 1);
          render();
          continue;
        }

        if (ev.type == KeyEventType.arrowRight || ev.type == KeyEventType.enter) {
          if (index == steps.length - 1) {
            break; // finish
          }
          index = (index + 1).clamp(0, steps.length - 1);
          render();
          continue;
        }
      }
    } finally {
      cleanup();
    }

    Terminal.clearAndHome();
    return cancelled ? -1 : index;
  }
}


