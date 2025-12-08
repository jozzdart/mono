import '../style/theme.dart';
import '../system/hints.dart';
import '../system/prompt_runner.dart';
import '../system/widget_frame.dart';

/// Theme-aware loading spinner with multiple visual styles.
///
/// Styles: dots (braille), bars (rising/falling), arcs (quarter/half circles).
///
/// **Usage:**
///
/// 1. **Static display** (caller controls updates):
/// ```dart
/// final spinner = LoadingSpinner('Loading');
/// spinner.show(frame: 0);
/// // ... do work ...
/// spinner.show(frame: 1);
/// spinner.clear();
/// ```
///
/// 2. **With callback** (caller drives progress):
/// ```dart
/// LoadingSpinner('Processing').runWith((tick) {
///   for (int i = 0; i < 10; i++) {
///     doWork();
///     tick();
///   }
/// });
/// ```
class LoadingSpinner with Themeable {
  final String label;
  final String message;
  final SpinnerStyle style;
  @override
  final PromptTheme theme;

  RenderOutput? _output;
  bool _started = false;

  /// Creates a loading spinner.
  LoadingSpinner(
    this.label, {
    this.message = 'Loading',
    this.style = SpinnerStyle.dots,
    this.theme = PromptTheme.dark,
  });

  @override
  LoadingSpinner copyWithTheme(PromptTheme theme) {
    return LoadingSpinner(
      label,
      message: message,
      style: style,
      theme: theme,
    );
  }

  /// Shows the spinner at the given frame.
  void show({required int frame}) {
    _output ??= RenderOutput();
    final out = _output!;

    if (_started) out.clear();
    _started = true;

    _render(out, frame);
  }

  /// Clears the spinner from the terminal.
  void clear() {
    _output?.clear();
    _output = null;
    _started = false;
  }

  /// Runs the spinner with a callback that provides tick updates.
  void runWith(void Function(void Function() tick) callback) {
    TerminalSession(hideCursor: true).run(() {
      int frame = 0;
      callback(() {
        show(frame: frame++);
      });
      clear();
    });
  }

  void _render(RenderOutput out, int frameIndex) {
    final frames = _framesForStyle(style);
      final widgetFrame = WidgetFrame(title: label, theme: theme);

    final color = (frameIndex % 2 == 0) ? theme.accent : theme.highlight;

      widgetFrame.showTo(out, (ctx) {
        final spin = frames[frameIndex % frames.length];
        ctx.gutterLine(
            '${theme.dim}$message${theme.reset}  ${theme.bold}$color$spin${theme.reset}');
      });

      out.writeln(Hints.bullets([
        'Theme-aware spinner',
        'Style: ${style.name}',
      ], theme, dim: true));
  }

  List<String> _framesForStyle(SpinnerStyle s) {
    switch (s) {
      case SpinnerStyle.dots:
        return const ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
      case SpinnerStyle.bars:
        return const [
          '▁',
          '▂',
          '▃',
          '▄',
          '▅',
          '▆',
          '▇',
          '█',
          '▇',
          '▆',
          '▅',
          '▄',
          '▃',
          '▂'
        ];
      case SpinnerStyle.arcs:
        return const ['◜', '◠', '◝', '◞', '◡', '◟'];
    }
  }
}

enum SpinnerStyle { dots, bars, arcs }

/// Simple inline spinner for minimal display.
class SimpleSpinner {
  final String message;
  final SpinnerStyle style;
  final PromptTheme theme;

  RenderOutput? _output;
  bool _started = false;

  SimpleSpinner(this.message,
      {this.style = SpinnerStyle.dots, this.theme = PromptTheme.dark});

  void show({required int frame}) {
    _output ??= RenderOutput();
    final out = _output!;

    if (_started) out.clear();
    _started = true;

    final frames = _framesForStyle(style);
    final spin = frames[frame % frames.length];
    out.writeln(
        '${theme.accent}$spin${theme.reset} ${theme.dim}$message${theme.reset}');
  }

  void clear() {
    _output?.clear();
    _output = null;
    _started = false;
  }

  List<String> _framesForStyle(SpinnerStyle s) {
    switch (s) {
      case SpinnerStyle.dots:
        return const ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
      case SpinnerStyle.bars:
        return const [
          '▁',
          '▂',
          '▃',
          '▄',
          '▅',
          '▆',
          '▇',
          '█',
          '▇',
          '▆',
          '▅',
          '▄',
          '▃',
          '▂'
        ];
      case SpinnerStyle.arcs:
        return const ['◜', '◠', '◝', '◞', '◡', '◟'];
    }
  }
}
