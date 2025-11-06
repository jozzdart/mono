import 'dart:io';

import '../style/theme.dart';
import 'context.dart';
import 'engine.dart';
import 'widget.dart';
import 'core/element.dart';
import 'render/buffer.dart';

/// Central renderer that takes a [Widget] tree and writes to stdout.
class TerminalRenderer {
  final Stdout out;

  TerminalRenderer({Stdout? out}) : out = out ?? stdout;

  /// Renders [root] with the provided theme using a fresh [RenderEngine].
  void renderApp(Widget root,
      {PromptTheme theme = const PromptTheme(), bool colorEnabled = true}) {
    final ctx = RenderContext.fromTerminal(
      theme: theme,
      colorEnabled: colorEnabled,
    );
    final owner = BuildOwner(ctx);
    owner.mountRoot(root);
    try {
      owner.buildDirty();
      final buffer = TerminalFrameBuffer();
      owner.pipeline.flushFrame(buffer);
      buffer.flushTo((line) => out.writeln(line), clearBefore: true);
    } catch (e, st) {
      final fb = TerminalFrameBuffer();
      fb.addLine('Render error: $e');
      fb.addLine(st.toString());
      fb.flushTo((line) => out.writeln(line), clearBefore: true);
    }
  }
}
