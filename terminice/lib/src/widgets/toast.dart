import 'package:terminice/terminice.dart';

/// Toast — a theme-aware popup message display.
///
/// **Usage:**
///
/// 1. **Static display** (caller controls lifetime):
/// ```dart
/// final toast = Toast('Saved!', variant: ToastVariant.success);
/// toast.show();
/// // ... do something ...
/// toast.clear();
/// ```
///
/// 2. **With callback** (shows during callback execution):
/// ```dart
/// Toast('Processing...', variant: ToastVariant.info).showWhile(() {
///   doWork();
/// });
/// ```
class Toast with Themeable {
  final String message;
  final String label;
  final ToastVariant variant;
  @override
  final PromptTheme theme;

  RenderOutput? _output;
  bool _started = false;

  /// Creates a toast notification.
  Toast(
    this.message, {
    this.label = 'Toast',
    this.variant = ToastVariant.info,
    this.theme = PromptTheme.dark,
  });

  @override
  Toast copyWithTheme(PromptTheme theme) {
    return Toast(
      message,
      label: label,
      variant: variant,
      theme: theme,
    );
  }

  /// Shows the toast.
  void show() {
    _output ??= RenderOutput();
    final out = _output!;

    if (_started) out.clear();
    _started = true;

    _render(out);
  }

  /// Clears the toast from the terminal.
  void clear() {
    _output?.clear();
    _output = null;
    _started = false;
  }

  /// Shows the toast while executing a callback, then clears it.
  T showWhile<T>(T Function() callback) {
    show();
    try {
      return callback();
    } finally {
      clear();
    }
  }

  void _render(RenderOutput out) {
    final color = _colorForVariant();
    final icon = _iconForVariant();

    final widgetFrame = FrameView(title: label, theme: theme);
    widgetFrame.showTo(out, (ctx) {
      final iconPart = '${theme.bold}$color$icon${theme.reset}';
      ctx.gutterLine('$iconPart $message');
    });

    out.writeln(Hints.bullets([
      'Toast notification',
    ], theme, dim: true));
  }

  String _iconForVariant() {
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

  String _colorForVariant() {
    switch (variant) {
      case ToastVariant.success:
        return theme.checkboxOn;
      case ToastVariant.warning:
        return theme.highlight;
      case ToastVariant.error:
        return '\x1B[31m';
      case ToastVariant.info:
        return theme.accent;
    }
  }
}

enum ToastVariant { info, success, warning, error }

/// Simple inline toast message.
class SimpleToast {
  final String message;
  final ToastVariant variant;
  final PromptTheme theme;

  RenderOutput? _output;
  bool _started = false;

  SimpleToast(this.message,
      {this.variant = ToastVariant.info, this.theme = PromptTheme.dark});

  void show() {
    _output ??= RenderOutput();
    final out = _output!;

    if (_started) out.clear();
    _started = true;

    final color = _colorForVariant();
    final icon = _iconForVariant();
    out.writeln('$color$icon${theme.reset} $message');
  }

  void clear() {
    _output?.clear();
    _output = null;
    _started = false;
  }

  String _iconForVariant() {
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

  String _colorForVariant() {
    switch (variant) {
      case ToastVariant.success:
        return theme.checkboxOn;
      case ToastVariant.warning:
        return theme.highlight;
      case ToastVariant.error:
        return '\x1B[31m';
      case ToastVariant.info:
        return theme.accent;
    }
  }
}
