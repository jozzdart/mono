import '../widget.dart';
import '../render/widgets.dart' as ro;
import '../render/object.dart';
import '../render/painting.dart';

enum Alignment { left, center, right }

class Align extends ro.SingleChildRenderObjectWidget {
  final Alignment alignment;

  const Align({required this.alignment, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderAlign(context.terminalColumns, alignment);
}

class _RenderAlign extends RenderContainerBox {
  int columns;
  Alignment alignment;
  _RenderAlign(this.columns, this.alignment);

  @override
  void performLayout() {
    for (final c in children) {
      c.layout(BoxConstraints(maxWidth: constraints.maxWidth));
    }
  }

  @override
  void paint(dynamic context) {
    if (context is! PaintContext) return;
    String alignLine(String line) {
      final len = line.runes.length;
      if (alignment == Alignment.left || len >= columns) return line;
      int leftPad = 0;
      switch (alignment) {
        case Alignment.center:
          leftPad = ((columns - len) ~/ 2).clamp(0, columns);
          break;
        case Alignment.right:
          leftPad = (columns - len).clamp(0, columns);
          break;
        default:
          leftPad = 0;
      }
      return '${' ' * leftPad}$line';
    }

    final transformed = _TransformPaintContext(context, alignLine);
    for (final c in children) {
      c.paint(transformed);
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
