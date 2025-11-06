import '../system/rendering.dart' as style_helpers;
import 'context.dart';
import 'modifiers.dart';

/// Low-level rendering engine that widgets use to print to the terminal.
///
/// Handles ANSI stripping (when color is disabled) and a scoped gutter mode.
class RenderEngine {
  final RenderContext context;
  final void Function(String line) _write;
  int _gutterDepth = 0;
  final List<WriteModifier> _mods = [];

  RenderEngine({required this.context, required void Function(String) write})
      : _write = write;

  /// Write a single line; applies gutter if currently enabled.
  void writeLine(String line) {
    String content = context.colorEnabled ? line : style_helpers.stripAnsi(line);
    for (final m in _mods) {
      content = m.apply(content, context);
    }
    if (_gutterDepth > 0) {
      _write(style_helpers.gutterLine(context.theme, content));
    } else {
      _write(content);
    }
  }

  /// Enable a gutter prefix for the duration of [fn]. Supports nesting.
  void withGutter(void Function() fn) {
    _gutterDepth += 1;
    try {
      fn();
    } finally {
      _gutterDepth -= 1;
    }
  }

  void push(WriteModifier modifier) => _mods.add(modifier);
  void pop(WriteModifier modifier) {
    if (_mods.isNotEmpty && identical(_mods.last, modifier)) {
      _mods.removeLast();
    } else {
      _mods.remove(modifier);
    }
  }
}

/// Simple screen buffer that accumulates a frame and flushes to an output.
class ScreenBuffer {
  final List<String> _curr = [];

  void add(String line) => _curr.add(line);

  /// Clears screen and writes the current frame. This is a safe default when
  /// cursor addressing is not implemented yet.
  void flushTo(void Function(String line) write, {bool clearBefore = true}) {
    if (clearBefore) {
      write('\x1B[2J\x1B[H'); // clear screen, cursor home
    }
    for (final l in _curr) {
      write(l);
    }
    _curr.clear();
  }
}
