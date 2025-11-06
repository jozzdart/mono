import '../widget.dart';
// import '../widgets.dart';
import '../render/widgets.dart' as ro;
import '../render/object.dart';
import '../render/painting.dart';

class Box extends Widget {
  final int width; // target width in columns
  final Widget child;
  Box({required this.width, required this.child});

  @override
  Widget? buildWidget(BuildContext context) => child;
}

class SizedBox extends ro.SingleChildRenderObjectWidget {
  final int? width;
  final int? height;
  const SizedBox({this.width, this.height, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizedBox(width: width, height: height);
}

class _RenderSizedBox extends RenderContainerBox {
  final int? width;
  final int? height;
  _RenderSizedBox({this.width, this.height});

  @override
  void performLayout() {
    for (final c in children) {
      c.layout(BoxConstraints(maxWidth: constraints.maxWidth));
    }
  }

  @override
  void paint(dynamic context) {
    if (context is! PaintContext) return;
    final h = height ?? 0;
    for (int i = 0; i < h; i++) {
      context.writeLine('');
    }
    for (final c in children) {
      c.paint(context);
    }
  }
}
