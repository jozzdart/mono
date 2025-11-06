import '../engine.dart';
import '../widget.dart';
import '../context.dart';
import 'object.dart';
import 'painting.dart';

/// Leaf render object that adapts a Printable to the render pipeline.
class RenderPrintableBox extends RenderBox {
  final RenderContext renderContext;
  Printable printable;
  RenderPrintableBox(this.renderContext, this.printable);

  @override
  void performLayout() {}

  @override
  void paint(dynamic context) {
    if (context is! PaintContext) return;
    final engine = RenderEngine(
      context: renderContext,
      write: (line) => context.buffer.addLine(line),
    );
    printable.render(engine);
  }
}


