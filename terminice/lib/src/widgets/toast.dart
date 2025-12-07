import 'dart:io' show sleep;

import '../style/prompt_config.dart';
import '../style/theme.dart';
import '../system/hints.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

/// Toast — a transient, theme-aware popup message that gently fades away.
///
/// **Configuration:** Supports both direct theme and [PromptConfig]:
/// ```dart
/// // Fluent API
/// Toast('Saved!', variant: ToastVariant.success).withMatrixTheme().run();
///
/// // With shared config
/// final config = PromptConfig.matrix;
/// Toast('Saved!', variant: ToastVariant.success, config: config).run();
/// ```
class Toast with Themeable {
  final String message;
  final String label;
  final ToastVariant variant;
  final Duration duration;
  final Duration fadeOut;
  final int fps;
  @override
  final PromptTheme theme;

  /// Creates a toast notification.
  ///
  /// Accepts either:
  /// - A [PromptConfig] object (theme extracted automatically)
  /// - A direct [theme] parameter (for convenience)
  Toast(
    this.message, {
    this.label = 'Toast',
    this.variant = ToastVariant.info,
    this.duration = const Duration(milliseconds: 1200),
    this.fadeOut = const Duration(milliseconds: 600),
    this.fps = 18,
    // Config object (preferred for shared configuration)
    PromptConfig? config,
    // Direct theme (for convenience)
    PromptTheme theme = PromptTheme.dark,
  })  : theme = config?.theme ?? theme,
        assert(fps > 0);

  @override
  Toast copyWithTheme(PromptTheme theme) {
    return Toast(
      message,
      label: label,
      variant: variant,
      duration: duration,
      fadeOut: fadeOut,
      fps: fps,
      theme: theme,
    );
  }

  void run() {
    int frameMs = (1000 / fps).clamp(12, 200).round();

    String iconForVariant() {
      switch (variant) {
        case ToastVariant.success:
          return '✔';
        case ToastVariant.warning:
          return '⚠';
        case ToastVariant.error:
          return '✖';
        case ToastVariant.info:
          return 'ℹ';
      }
    }

    String colorForVariant() {
      switch (variant) {
        case ToastVariant.success:
          return theme.checkboxOn; // green-ish
        case ToastVariant.warning:
          return theme.highlight; // yellow-ish
        case ToastVariant.error:
          return '\x1B[31m'; // red
        case ToastVariant.info:
          return theme.accent; // cyan/pastel
      }
    }

    void render(RenderOutput out, double opacity) {
      // Fade styling: blend dim/gray as opacity decreases.
      final bool dimPhase = opacity < 0.85;
      final bool grayPhase = opacity < 0.55;
      final color = colorForVariant();
      final icon = iconForVariant();

      String applyFade(String s) {
        if (grayPhase) return '${theme.gray}$s${theme.reset}';
        if (dimPhase) return '${theme.dim}$s${theme.reset}';
        return s;
      }

      final widgetFrame = WidgetFrame(title: label, theme: theme);
      widgetFrame.showTo(out, (ctx) {
        final iconPart = applyFade('${theme.bold}$color$icon${theme.reset}');
        final msgPart = applyFade(message);
        ctx.gutterLine('$iconPart $msgPart');
      });

      out.writeln(Hints.bullets([
        'Fades automatically',
      ], theme, dim: true));
    }

    // Use TerminalSession for cursor hiding + RenderOutput for partial clearing
    TerminalSession(hideCursor: true).runWithOutput((out) {
      // Initial render
      render(out, 1.0);

      // Hold phase
      final holdEnd = DateTime.now().add(duration);
      while (DateTime.now().isBefore(holdEnd)) {
        sleep(Duration(milliseconds: frameMs));
        out.clear();
        render(out, 1.0);
      }

      // Fade-out phase
      final totalFrames =
          (fadeOut.inMilliseconds / frameMs).clamp(1, 240).round();
      for (int i = 0; i <= totalFrames; i++) {
        final t = i / totalFrames; // 0..1
        final eased = _easeOutCubic(1 - t); // 1..0
        out.clear();
        render(out, eased);
        sleep(Duration(milliseconds: frameMs));
      }
    }, clearOnEnd: true);
  }
}

enum ToastVariant { info, success, warning, error }

double _easeOutCubic(double t) {
  final f = t - 1;
  return f * f * f + 1;
}
