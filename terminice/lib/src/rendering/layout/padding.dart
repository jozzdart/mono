import '../widget.dart';
// import '../engine.dart';
import '../render/widgets.dart' as ro;
import '../render/object.dart';
import '../render/painting.dart';

class EdgeInsets {
  final int left, top, right, bottom;
  const EdgeInsets._(this.left, this.top, this.right, this.bottom);
  const EdgeInsets.all(int v) : this._(v, v, v, v);
  const EdgeInsets.symmetric({int horizontal = 0, int vertical = 0})
      : this._(horizontal, vertical, horizontal, vertical);
}

class Padding extends ro.SingleChildRenderObjectWidget {
  final EdgeInsets padding;
  const Padding({required this.padding, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPadding(padding);
}

class _RenderPadding extends RenderContainerBox {
  final EdgeInsets padding;
  _RenderPadding(this.padding);

  @override
  void performLayout() {
    for (final c in children) {
      c.layout(BoxConstraints(maxWidth: constraints.maxWidth - padding.left));
    }
  }

  @override
  void paint(dynamic context) {
    if (context is! PaintContext) return;
    for (int i = 0; i < padding.top; i++) {
      context.writeLine('');
    }
    final leftPad = ' ' * padding.left;
    final transformed =
        _TransformPaintContext(context, (line) => '$leftPad$line');
    for (final c in children) {
      c.paint(transformed);
    }
    for (int i = 0; i < padding.bottom; i++) {
      context.writeLine('');
    }
  }
}

class _TransformPaintContext extends PaintContext {
  final String Function(String) transform;
  _TransformPaintContext(PaintContext base, this.transform)
      : super(base.renderContext, base.buffer);
  @override
  void writeLine(String line) {
    super.writeLine(transform(line));
  }
}
