import '../widget.dart';
import '../core/element.dart';
import '../engine.dart';
import 'object.dart';
import 'adapters.dart';

abstract class RenderObjectWidget extends Widget {
  const RenderObjectWidget();
  RenderObject createRenderObject(BuildContext context);
  void updateRenderObject(
      covariant RenderObject renderObject, BuildContext context) {}
}

abstract class LeafRenderObjectWidget extends RenderObjectWidget {
  const LeafRenderObjectWidget();
}

abstract class SingleChildRenderObjectWidget extends RenderObjectWidget {
  final Widget? child;
  const SingleChildRenderObjectWidget({this.child});
}

abstract class MultiChildRenderObjectWidget extends RenderObjectWidget {
  final List<Widget> children;
  const MultiChildRenderObjectWidget({this.children = const []});
}

// Elements
abstract class RenderObjectElement extends Element {
  late final RenderObject renderObject;
  RenderObjectElement(RenderObjectWidget super.widget, super.inherited);

  @override
  void didMount() {
    final ctx = BuildContext.internal(owner.renderContext, inherited,
        owner: owner, parentElement: this);
    renderObject = (widget as RenderObjectWidget).createRenderObject(ctx);
    owner.pipeline.attach(renderObject);
    owner.pipeline.root ??= renderObject;
  }

  @override
  void didUnmount() {
    owner.pipeline.detach(renderObject);
  }
}

class LeafRenderObjectElement extends RenderObjectElement {
  LeafRenderObjectElement(LeafRenderObjectWidget super.widget, super.inherited);

  @override
  void performRebuild() {
    // Nothing to reconcile; leaf has no children
  }
}

class SingleChildRenderObjectElement extends RenderObjectElement {
  SingleChildRenderObjectElement(
      SingleChildRenderObjectWidget super.widget, super.inherited);

  @override
  void performRebuild() {
    beginChildReconcile();
    final w = widget as SingleChildRenderObjectWidget;
    final inh = Map<Type, Object>.from(inherited);
    if (w.child != null) {
      final Widget childWidget = w.child is RenderObjectWidget
          ? (w.child as RenderObjectWidget)
          : WidgetAdapter(w.child!);
      reuseOrInflateChild(childWidget, Map<Type, Object>.from(inh));
    }
    endChildReconcile();

    if (renderObject is RenderContainerBox) {
      final ros = <RenderBox>[];
      for (final e in children) {
        if (e is RenderObjectElement && e.renderObject is RenderBox) {
          (e.renderObject as RenderBox).parent = renderObject;
          ros.add(e.renderObject as RenderBox);
        }
      }
      (renderObject as RenderContainerBox).setChildren(ros);
    }
  }
}

class MultiChildRenderObjectElement extends RenderObjectElement {
  MultiChildRenderObjectElement(
      MultiChildRenderObjectWidget super.widget, super.inherited);

  @override
  void performRebuild() {
    beginChildReconcile();
    final w = widget as MultiChildRenderObjectWidget;
    final inh = Map<Type, Object>.from(inherited);
    for (final child in w.children) {
      // Ensure child is a RenderObjectWidget by wrapping if needed
      final Widget childWidget =
          child is RenderObjectWidget ? child : WidgetAdapter(child);
      reuseOrInflateChild(childWidget, Map<Type, Object>.from(inh));
    }
    endChildReconcile();

    // Connect render tree: parent must be a container
    if (renderObject is RenderContainerBox) {
      final ros = <RenderBox>[];
      for (final e in children) {
        if (e is RenderObjectElement && e.renderObject is RenderBox) {
          (e.renderObject as RenderBox).parent = renderObject;
          ros.add(e.renderObject as RenderBox);
        }
      }
      (renderObject as RenderContainerBox).setChildren(ros);
    }
  }
}

// Container base for convenience
abstract class RenderContainerBox extends RenderBox {
  List<RenderBox> _children = const [];
  void setChildren(List<RenderBox> children) {
    _children = children;
    markNeedsLayout();
    markNeedsPaint();
  }

  List<RenderBox> get children => _children;
}

// Adapter that allows using normal Widgets inside render tree
class WidgetAdapter extends LeafRenderObjectWidget {
  final Widget child;
  const WidgetAdapter(this.child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderPrintableBox(
      context.renderContext,
      _WidgetPrintable(child, context.snapshotInherited()),
    );
  }
}

class _WidgetPrintable implements Printable {
  final Widget child;
  final Map<Type, Object> inherited;
  _WidgetPrintable(this.child, this.inherited);
  @override
  void render(RenderEngine engine) {
    child.renderWithInherited(engine, inherited);
  }
}
