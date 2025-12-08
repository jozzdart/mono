import 'dart:async';
import 'dart:io' show sleep, stdout;

import '../style/theme.dart';
import 'hints.dart';

import 'prompt_runner.dart';
import 'widget_frame.dart';

// ════════════════════════════════════════════════════════════════════════════
// ANIMATION SUPPORT
// ════════════════════════════════════════════════════════════════════════════

/// AnimatedFrame – runs an animation loop with frame-based rendering.
///
/// Simplifies creating animated widgets by handling:
/// - TerminalSession for cursor hiding
/// - RenderOutput for partial clearing
/// - Timing and frame control
///
/// Example:
/// ```dart
/// AnimatedFrame(
///   title: 'Loading',
///   theme: theme,
///   duration: Duration(seconds: 2),
///   fps: 12,
/// ).run((ctx, phase) {
///   final spin = InlineStyle(theme).spinner(phase);
///   ctx.gutterLine('Processing... $spin');
/// });
/// ```
class AnimatedFrame {
  final String title;
  final PromptTheme theme;
  final Duration duration;
  final int fps;
  final bool clearOnEnd;
  final List<String>? hints;

  AnimatedFrame({
    required this.title,
    required this.theme,
    this.duration = const Duration(seconds: 2),
    this.fps = 12,
    this.clearOnEnd = true,
    this.hints,
  }) : assert(fps > 0);

  /// Runs the animation loop.
  ///
  /// [content] receives the FrameContext and current frame phase.
  void run(void Function(FrameContext ctx, int phase) content) {
    final int frameMs = (1000 / fps).clamp(12, 200).round();

    void render(RenderOutput out, int phase) {
      final frame = WidgetFrame(title: title, theme: theme);
      frame.showTo(out, (ctx) => content(ctx, phase));

      if (hints != null && hints!.isNotEmpty) {
        out.writeln(Hints.bullets(hints!, theme, dim: true));
      }
    }

    TerminalSession(hideCursor: true).runWithOutput((out) {
      final sw = Stopwatch()..start();
      int phase = 0;

      render(out, phase);
      phase++;

      while (sw.elapsed < duration) {
        sleep(Duration(milliseconds: frameMs));
        out.clear();
        render(out, phase);
        phase++;
      }
    }, clearOnEnd: clearOnEnd);
  }

  /// Runs an indefinite animation until [stop] is called.
  ///
  /// Returns a controller to stop the animation.
  AnimationController runIndefinite(
      void Function(FrameContext ctx, int phase) content) {
    final controller = AnimationController._();
    final int frameMs = (1000 / fps).clamp(12, 200).round();

    void render(RenderOutput out, int phase) {
      final frame = WidgetFrame(title: title, theme: theme);
      frame.showTo(out, (ctx) => content(ctx, phase));

      if (hints != null && hints!.isNotEmpty) {
        out.writeln(Hints.bullets(hints!, theme, dim: true));
      }
    }

    // Run in async context to allow stopping
    Future<void>.microtask(() {
      TerminalSession(hideCursor: true).runWithOutput((out) {
        int phase = 0;
        render(out, phase);
        phase++;

        while (!controller._stopped) {
          sleep(Duration(milliseconds: frameMs));
          out.clear();
          render(out, phase);
          phase++;
        }
      }, clearOnEnd: clearOnEnd);
    });

    return controller;
  }
}

/// Controller for indefinite animations.
class AnimationController {
  bool _stopped = false;

  AnimationController._();

  /// Stops the animation.
  void stop() {
    _stopped = true;
  }

  /// Whether the animation has been stopped.
  bool get isStopped => _stopped;
}

// ════════════════════════════════════════════════════════════════════════════
// PERSISTENT STATUS LINE
// ════════════════════════════════════════════════════════════════════════════

/// PersistentLine – renders a persistent status line at the bottom of the terminal.
///
/// Uses the InlineStyle system for consistent theming.
///
/// Example:
/// ```dart
/// final status = PersistentLine(label: 'Build', theme: theme)..start();
/// status.update('Compiling sources');
/// status.success('Done');
/// status.stop();
/// ```
class PersistentLine {
  final String label;
  final PromptTheme theme;
  final bool showSpinner;
  final Duration spinnerInterval;

  late final InlineStyle _inline;
  Timer? _spinnerTimer;
  int _spinnerPhase = 0;
  String _message = '';
  bool _running = false;

  PersistentLine({
    required this.label,
    this.theme = PromptTheme.dark,
    this.showSpinner = true,
    this.spinnerInterval = const Duration(milliseconds: 120),
  }) {
    _inline = InlineStyle(theme);
  }

  /// Begin rendering the persistent status line.
  void start() {
    if (_running) return;
    _running = true;
    _render();
    if (showSpinner) {
      _spinnerTimer = Timer.periodic(spinnerInterval, (_) {
        _spinnerPhase++;
        _render();
      });
    }
  }

  /// Update the message on the status line.
  void update(String message) {
    _message = message;
    _render();
  }

  /// Show a success state and freeze the spinner.
  void success(String message) {
    _message = message;
    _render(icon: _inline.successIcon());
    _stopSpinner();
  }

  /// Show an error state and freeze the spinner.
  void error(String message) {
    _message = message;
    _render(icon: _inline.errorIcon());
    _stopSpinner();
  }

  /// Show a warning state.
  void warning(String message) {
    _message = message;
    _render(icon: _inline.warnIcon());
    _stopSpinner();
  }

  /// Stop rendering and clean up resources.
  ///
  /// Important: Always call this when done to prevent timer leaks.
  void stop() {
    _stopSpinner();
    _running = false;
  }

  /// Disposes resources. Alias for [stop].
  void dispose() => stop();

  void _stopSpinner() {
    _spinnerTimer?.cancel();
    _spinnerTimer = null;
  }

  void _render({String? icon}) {
    if (!_running) return;
    final s = theme.style;

    final prefix = _inline.gray(s.borderBottom);
    final title = _inline.selection(' $label ');
    final spin = icon ?? (showSpinner ? _inline.spinner(_spinnerPhase) : ' ');
    final msg = _message.isEmpty ? '' : _inline.gray(_message);

    final line = StringBuffer()
      ..write(prefix)
      ..write(' ')
      ..write(title)
      ..write('  ')
      ..write(spin)
      ..write('  ')
      ..write(msg);

    _writeBottom(line.toString());
  }

  void _writeBottom(String text) {
    stdout.write('\x1B7'); // Save cursor
    stdout.write('\x1B[999;1H'); // Move to bottom
    stdout
      ..write('\x1B[2K') // Clear line
      ..writeln(text);
    stdout.write('\x1B8'); // Restore cursor
  }
}
