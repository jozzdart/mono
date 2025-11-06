import '../context.dart';
import 'buffer.dart';
import 'object.dart';
import 'painting.dart';

class PipelineOwner {
  final RenderContext renderContext;
  final Set<RenderObject> _dirtyLayout = {};
  final Set<RenderObject> _dirtyPaint = {};
  RenderObject? root;

  PipelineOwner(this.renderContext);

  void requestLayout(RenderObject node) {
    _dirtyLayout.add(node);
  }

  void requestPaint(RenderObject node) {
    _dirtyPaint.add(node);
  }

  void attach(RenderObject node) {
    node.attach(this);
  }

  void detach(RenderObject node) {
    node.detach();
  }

  void flushLayout() {
    if (root == null) return;
    // Simple: layout root with terminal width constraint.
    final constraints = BoxConstraints(maxWidth: renderContext.terminalColumns);
    root!.layout(constraints);
    _dirtyLayout.clear();
  }

  void flushPaint(TerminalFrameBuffer buffer) {
    if (root == null) return;
    final ctx = PaintContext(renderContext, buffer);
    root!.paint(ctx);
    _dirtyPaint.clear();
  }

  void flushFrame(TerminalFrameBuffer buffer) {
    flushLayout();
    flushPaint(buffer);
  }
}


