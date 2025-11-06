import '../widget.dart';
import '../context.dart';
import '../inherited.dart' show InheritedWidget;

class BuildOwner {
  final RenderContext renderContext;
  final List<Element> _dirty = [];

  BuildOwner(this.renderContext);

  Element mountRoot(Widget root) {
    final e = _inflate(root, const {});
    e.mount(this, const {});
    scheduleBuild(e);
    return e;
  }

  void scheduleBuild(Element e) {
    if (!_dirty.contains(e)) _dirty.add(e);
  }

  void buildDirty() {
    final toBuild = List<Element>.from(_dirty);
    _dirty.clear();
    for (final e in toBuild) {
      e.performRebuild();
    }
  }

  Element _inflate(Widget widget, Map<Type, Object> inherited) {
    if (widget is InheritedWidget) {
      return InheritedElement(widget, inherited);
    }
    if (widget is StatefulWidget) {
      return StatefulElement(widget, inherited);
    }
    return StatelessElement(widget, inherited);
  }

  Element inflateWidget(Widget widget, Map<Type, Object> inherited) =>
      _inflate(widget, inherited);
}

abstract class Element {
  Widget widget;
  final Map<Type, Object> inherited;
  late final BuildOwner owner;
  List<Printable> _outputs = const [];
  // Ordered children maintained across rebuilds for unkeyed reconciliation.
  List<Element> _children = const [];
  Map<Key, Element> _childrenByKey = {};
  Map<Key, Element> _nextChildrenByKey = {};
  final Set<Element> _dependents = {};
  // Next-frame children during reconciliation.
  List<Element> _nextChildren = const [];
  int _childIndex = 0;

  Element(this.widget, this.inherited);

  void mount(BuildOwner owner, Map<Type, Object> map) {
    this.owner = owner;
    didMount();
  }

  void didMount() {}

  void performRebuild();

  List<Printable> get outputs => _outputs;

  void setOutputs(List<Printable> out) {
    _outputs = out;
  }

  void updateWidget(Widget newWidget) {
    widget = newWidget;
    owner.scheduleBuild(this);
  }

  void beginChildReconcile() {
    _nextChildrenByKey = {};
    _nextChildren = <Element>[];
    _childIndex = 0;
  }

  Element reuseOrInflateChild(Widget childWidget, Map<Type, Object> inh) {
    final k = childWidget.key;
    // Keyed path: prefer by-key reuse independent of position.
    if (k != null) {
      final existing = _childrenByKey.remove(k);
      if (existing != null) {
        existing.updateWidget(childWidget);
        _nextChildrenByKey[k] = existing;
        _nextChildren.add(existing);
        return existing;
      }
      final el = owner.inflateWidget(childWidget, inh);
      el.mount(owner, inh);
      owner.scheduleBuild(el);
      _nextChildrenByKey[k] = el;
      _nextChildren.add(el);
      return el;
    }

    // Unkeyed path: attempt ordered reuse by index and runtimeType.
    if (_childIndex < _children.length) {
      final candidate = _children[_childIndex];
      if (candidate.widget.runtimeType == childWidget.runtimeType) {
        candidate.updateWidget(childWidget);
        _nextChildren.add(candidate);
        _childIndex += 1;
        return candidate;
      }
    }

    // Fallback: inflate new element.
    final el = owner.inflateWidget(childWidget, inh);
    el.mount(owner, inh);
    owner.scheduleBuild(el);
    _nextChildren.add(el);
    return el;
  }

  void endChildReconcile() {
    _childrenByKey = _nextChildrenByKey;
    _children = _nextChildren;
  }

  void registerDependent(Element e) {
    _dependents.add(e);
  }

  void notifyDependents() {
    for (final d in _dependents) {
      owner.scheduleBuild(d);
    }
  }
}

class StatelessElement extends Element {
  StatelessElement(super.widget, super.inherited);

  @override
  void performRebuild() {
    beginChildReconcile();
    final ctx = BuildContext.internal(owner.renderContext, inherited,
        owner: owner, parentElement: this);
    widget.build(ctx);
    setOutputs(ctx.children);
    endChildReconcile();
  }
}

class StatefulElement extends Element {
  late final State state;

  StatefulElement(StatefulWidget super.widget, super.inherited);

  @override
  void didMount() {
    final w = widget as StatefulWidget;
    state = w.createState();
    state.attach(w, owner, this);
  }

  @override
  void performRebuild() {
    beginChildReconcile();
    final ctx = BuildContext.internal(owner.renderContext, inherited,
        owner: owner, parentElement: this);
    state.build(ctx);
    setOutputs(ctx.children);
    endChildReconcile();
  }
}

class InheritedElement extends Element {
  Object? _lastValue;

  InheritedElement(InheritedWidget super.widget, super.inherited);

  @override
  void didMount() {
    _lastValue = (widget as InheritedWidget).value;
  }

  @override
  void performRebuild() {
    beginChildReconcile();
    final ctx = BuildContext.internal(owner.renderContext, inherited,
        owner: owner, parentElement: this);
    widget.build(ctx);
    setOutputs(ctx.children);
    endChildReconcile();

    final current = (widget as InheritedWidget).value;
    if (_lastValue != current) {
      _lastValue = current;
      notifyDependents();
    }
  }
}
