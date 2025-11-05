import 'dart:io';

import '../style/theme.dart';
import '../system/hints.dart';
import '../system/terminal.dart';
import '../system/framed_layout.dart';

/// Toast — a transient, theme-aware popup message that gently fades away.
///
/// Usage:
///   Toast('Saved successfully', variant: ToastVariant.success).run();
class Toast {
  final String message;
  final String label;
  final ToastVariant variant;
  final Duration duration;
  final Duration fadeOut;
  final int fps;
  final PromptTheme theme;

  Toast(
    this.message, {
    this.label = 'Toast',
    this.variant = ToastVariant.info,
    this.duration = const Duration(milliseconds: 1200),
    this.fadeOut = const Duration(milliseconds: 600),
    this.fps = 18,
    this.theme = PromptTheme.dark,
  }) : assert(fps > 0);

  void run() {
    final style = theme.style;

    final term = Terminal.enterRaw();
    Terminal.hideCursor();

    void cleanup() {
      term.restore();
      Terminal.showCursor();
    }

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

    void render(double opacity) {
      Terminal.clearAndHome();

      final frame = FramedLayout(label, theme: theme);
      final top = frame.top();

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

      stdout.writeln('${theme.bold}$top${theme.reset}');

      final line = StringBuffer();
      line.write('${theme.gray}${style.borderVertical}${theme.reset} ');
      line.write(applyFade('${theme.bold}$color$icon${theme.reset} '));
      line.write(applyFade(message));
      stdout.writeln(line.toString());

      if (style.showBorder) {
        stdout.writeln(frame.bottom());
      }

      stdout.writeln(Hints.bullets([
        'Fades automatically',
      ], theme, dim: true));
    }

    try {
      // Hold phase
      final holdEnd = DateTime.now().add(duration);
      while (DateTime.now().isBefore(holdEnd)) {
        render(1.0);
        sleep(Duration(milliseconds: frameMs));
      }

      // Fade-out phase
      final totalFrames = (fadeOut.inMilliseconds / frameMs).clamp(1, 240).round();
      for (int i = 0; i <= totalFrames; i++) {
        final t = i / totalFrames; // 0..1
        final eased = _easeOutCubic(1 - t); // 1..0
        render(eased);
        sleep(Duration(milliseconds: frameMs));
      }
    } finally {
      cleanup();
    }

    Terminal.clearAndHome();
  }
}

enum ToastVariant { info, success, warning, error }

double _easeOutCubic(double t) {
  final f = t - 1;
  return f * f * f + 1;
}


