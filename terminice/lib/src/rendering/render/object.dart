import 'pipeline.dart';

abstract class Constraints {}

class BoxConstraints implements Constraints {
  final int maxWidth;
  const BoxConstraints({required this.maxWidth});
}

abstract class RenderObject {
  RenderObject? parent;
  PipelineOwner? owner;
  bool _needsLayout = true;
  bool _needsPaint = true;

  void attach(PipelineOwner owner) {
    this.owner = owner;
    markNeedsLayout();
    markNeedsPaint();
  }

  void detach() {
    owner = null;
  }

  void markNeedsLayout() {
    if (_needsLayout) return;
    _needsLayout = true;
    owner?.requestLayout(this);
  }

  void markNeedsPaint() {
    if (_needsPaint) return;
    _needsPaint = true;
    owner?.requestPaint(this);
  }

  void layout(covariant Constraints constraints);
  void paint(covariant dynamic context);

  void visitChildren(void Function(RenderObject child) visitor) {}
}

abstract class RenderBox extends RenderObject {
  late BoxConstraints _constraints;

  @override
  void layout(covariant BoxConstraints constraints) {
    _constraints = constraints;
    performLayout();
    _needsLayout = false;
  }

  BoxConstraints get constraints => _constraints;

  void performLayout();
}

abstract class RenderContainerBox extends RenderBox {
  List<RenderBox> _children = const [];
  void setChildren(List<RenderBox> children) {
    _children = children;
    for (final c in _children) {
      c.parent = this;
    }
    markNeedsLayout();
    markNeedsPaint();
  }

  List<RenderBox> get children => _children;
}


