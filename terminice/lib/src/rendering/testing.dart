// import 'engine.dart';
import 'widget.dart';
import 'context.dart';
import 'core/element.dart';
import 'render/buffer.dart';

/// TestRenderer captures output lines into a buffer for assertions.
class TestRenderer {
  final List<String> lines = [];

  void render(Widget root, {required RenderContext context}) {
    final owner = BuildOwner(context);
    owner.mountRoot(root);
    try {
      owner.buildDirty();
      final buffer = TerminalFrameBuffer();
      owner.pipeline.flushFrame(buffer);
      buffer.flushTo((line) => lines.add(line), clearBefore: false);
    } catch (e, st) {
      final fb = TerminalFrameBuffer();
      fb.addLine('Test render error: $e');
      fb.addLine(st.toString());
      fb.flushTo((line) => lines.add(line), clearBefore: false);
    }
  }
}
