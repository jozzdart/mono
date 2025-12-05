import 'dart:async';
import 'dart:io';

import 'terminal.dart';
import 'key_events.dart';

/// Result from a prompt indicating whether it was confirmed or cancelled.
enum PromptResult { confirmed, cancelled }

/// A line-tracking output buffer that only clears what it wrote.
///
/// Instead of clearing the entire terminal, this tracks how many lines
/// were written and uses cursor movement to clear just those lines
/// before re-rendering. This preserves any terminal content that existed
/// before the widget started.
class RenderOutput {
  int _lineCount = 0;

  /// Number of lines written since the last clear.
  int get lineCount => _lineCount;

  /// Writes a line to stdout and tracks it.
  void writeln([String line = '']) {
    stdout.writeln(line);
    // Count the line itself plus any embedded newlines
    _lineCount += 1 + '\n'.allMatches(line).length;
  }

  /// Writes text without a trailing newline (newlines in text are counted).
  void write(String text) {
    stdout.write(text);
    _lineCount += '\n'.allMatches(text).length;
  }

  /// Clears only the lines we wrote by moving cursor up and erasing.
  /// This preserves terminal content from before the widget started.
  /// Call this before re-rendering to update the display.
  void clear() {
    if (_lineCount > 0) {
      // Move cursor up by the number of lines we wrote
      stdout.write('\x1B[${_lineCount}A');
      // Clear from cursor to end of screen (only our content)
      stdout.write('\x1B[0J');
    }
    _lineCount = 0;
  }
}

/// Configuration for end-of-prompt behavior.
class EndBehavior {
  /// Whether to clear the widget's output when the prompt ends.
  /// If false, the final render remains visible.
  final bool clearOnEnd;

  const EndBehavior({this.clearOnEnd = true});

  /// Default: clears widget output when done (returns to clean terminal).
  static const EndBehavior clear = EndBehavior(clearOnEnd: true);

  /// Keeps the final render visible after the prompt ends.
  static const EndBehavior persist = EndBehavior(clearOnEnd: false);
}

/// A centralized runner for interactive terminal prompts.
///
/// This utility encapsulates the common lifecycle pattern used across all
/// terminice widgets:
/// 1. Enter raw terminal mode
/// 2. Hide cursor (optional)
/// 3. Run render/update loop (clearing only widget output between renders)
/// 4. Cleanup on exit
/// 5. Restore terminal state
///
/// **Key feature**: Never clears the entire terminal. Only clears lines
/// written by the widget itself, preserving any existing terminal content.
///
/// Usage:
/// ```dart
/// final runner = PromptRunner();
/// final result = runner.run(
///   render: (out) {
///     out.writeln('My widget content');
///     out.writeln('More content');
///   },
///   onKey: (event) {
///     if (event.type == KeyEventType.enter) return PromptResult.confirmed;
///     if (event.type == KeyEventType.esc) return PromptResult.cancelled;
///     return null; // continue loop
///   },
/// );
/// ```
class PromptRunner {
  /// Whether to hide the terminal cursor during the prompt.
  final bool hideCursor;

  /// Controls what happens when the prompt ends.
  final EndBehavior endBehavior;

  /// Optional callback invoked before cleanup (e.g., for final animations).
  final void Function()? onBeforeCleanup;

  /// Optional callback invoked after cleanup completes.
  final void Function()? onAfterCleanup;

  PromptRunner({
    this.hideCursor = true,
    this.endBehavior = EndBehavior.clear,
    this.onBeforeCleanup,
    this.onAfterCleanup,
  });

  /// Runs the prompt loop synchronously.
  ///
  /// [render] is called with a [RenderOutput] to write content.
  /// [onKey] handles key events and returns:
  ///   - `PromptResult.confirmed` to exit with success
  ///   - `PromptResult.cancelled` to exit with cancellation
  ///   - `null` to continue the loop
  PromptResult run({
    required void Function(RenderOutput out) render,
    required PromptResult? Function(KeyEvent event) onKey,
  }) {
    final term = Terminal.enterRaw();
    final output = RenderOutput();

    void cleanup() {
      onBeforeCleanup?.call();
      term.restore();
      Terminal.showCursor();
      onAfterCleanup?.call();
    }

    if (hideCursor) Terminal.hideCursor();

    // Initial render (no clearing needed - nothing written yet)
    render(output);

    PromptResult result = PromptResult.cancelled;

    try {
      while (true) {
        final event = KeyEventReader.read();
        final action = onKey(event);

        if (action != null) {
          result = action;
          break;
        }

        // Clear only our output, then re-render
        output.clear();
        render(output);
      }
    } finally {
      cleanup();
    }

    // Optionally clear our final output
    if (endBehavior.clearOnEnd) {
      output.clear();
    }

    return result;
  }

  /// Runs custom logic within a managed terminal session.
  ///
  /// This gives you full control over the render/input flow while still
  /// benefiting from centralized terminal management and [RenderOutput]
  /// for partial clearing.
  ///
  /// Use this for widgets that need:
  /// - Entry/exit animations
  /// - Custom render timing
  /// - Non-standard input loops
  ///
  /// Example (slider with animations):
  /// ```dart
  /// final runner = PromptRunner();
  /// final value = runner.runCustom((out) {
  ///   // Entry animation
  ///   for (int i = 0; i <= 10; i++) {
  ///     out.clear();
  ///     renderSlider(out, progress: i / 10);
  ///     sleep(Duration(milliseconds: 16));
  ///   }
  ///
  ///   // Main input loop
  ///   while (true) {
  ///     final ev = KeyEventReader.read();
  ///     if (ev.type == KeyEventType.enter) break;
  ///     // handle keys...
  ///     out.clear();
  ///     renderSlider(out);
  ///   }
  ///
  ///   // Exit animation
  ///   for (int i = 0; i < 3; i++) {
  ///     out.clear();
  ///     renderSlider(out, flash: i.isEven);
  ///     sleep(Duration(milliseconds: 20));
  ///   }
  ///
  ///   return finalValue;
  /// });
  /// ```
  T runCustom<T>(T Function(RenderOutput out) body) {
    final term = Terminal.enterRaw();
    final output = RenderOutput();

    if (hideCursor) Terminal.hideCursor();

    try {
      return body(output);
    } finally {
      onBeforeCleanup?.call();
      term.restore();
      Terminal.showCursor();
      onAfterCleanup?.call();

      // Optionally clear our final output
      if (endBehavior.clearOnEnd) {
        output.clear();
      }
    }
  }

  /// Runs the prompt loop asynchronously with optional blinking cursor support.
  ///
  /// [render] is called with a [RenderOutput] to write content.
  /// [onKey] handles key events.
  /// [cursorBlink] when provided, manages blinking cursor state.
  Future<PromptResult> runAsync({
    required void Function(RenderOutput out) render,
    required PromptResult? Function(KeyEvent event) onKey,
    CursorBlink? cursorBlink,
  }) async {
    final term = Terminal.enterRaw();
    final output = RenderOutput();
    Timer? blinkTimer;

    void doRender() {
      output.clear();
      render(output);
    }

    void cleanup() {
      blinkTimer?.cancel();
      onBeforeCleanup?.call();
      term.restore();
      Terminal.showCursor();
      onAfterCleanup?.call();
    }

    if (hideCursor) Terminal.hideCursor();

    // Setup cursor blink timer if configured
    if (cursorBlink != null) {
      blinkTimer = Timer.periodic(cursorBlink.interval, (_) {
        cursorBlink.toggle();
        doRender();
      });
    }

    // Initial render
    render(output);

    PromptResult result = PromptResult.cancelled;

    try {
      while (true) {
        final event = KeyEventReader.read();

        // Reset cursor visibility on key input
        cursorBlink?.resetOnInput();

        // Restart blink timer on input
        if (cursorBlink != null) {
          blinkTimer?.cancel();
          blinkTimer = Timer.periodic(cursorBlink.interval, (_) {
            cursorBlink.toggle();
            doRender();
          });
        }

        final action = onKey(event);

        if (action != null) {
          result = action;
          break;
        }

        doRender();
      }
    } finally {
      cleanup();
    }

    // Optionally clear our final output
    if (endBehavior.clearOnEnd) {
      output.clear();
    }

    return result;
  }
}

/// Configuration for cursor blinking in async prompts.
class CursorBlink {
  /// Interval between blink toggles.
  final Duration interval;

  /// Current visibility state.
  bool _visible = true;

  /// Whether the cursor should be visible.
  bool get isVisible => _visible;

  /// Creates a cursor blink configuration.
  CursorBlink({
    this.interval = const Duration(milliseconds: 500),
  });

  /// Toggles the cursor visibility.
  void toggle() {
    _visible = !_visible;
  }

  /// Resets cursor to visible (called on user input).
  void resetOnInput() {
    _visible = true;
  }
}
