import '../widget.dart';
import '../context.dart';
import '../inherited.dart' show InheritedWidget;
import '../render/widgets.dart' as ro_widgets;
import '../render/pipeline.dart';

class BuildOwner {
  final RenderContext renderContext;
  final List<Element> _dirty = [];
  final Map<GlobalKey, Element> _globalElements = {};
  final PipelineOwner pipeline;

  BuildOwner(this.renderContext) : pipeline = PipelineOwner(renderContext);

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
    if (widget is ro_widgets.RenderObjectWidget) {
      if (widget is ro_widgets.MultiChildRenderObjectWidget) {
        return ro_widgets.MultiChildRenderObjectElement(widget, inherited);
      }
      if (widget is ro_widgets.LeafRenderObjectWidget) {
        return ro_widgets.LeafRenderObjectElement(widget, inherited);
      }
      if (widget is ro_widgets.SingleChildRenderObjectWidget) {
        return ro_widgets.SingleChildRenderObjectElement(widget, inherited);
      }
    }
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

  void registerGlobal(Element e) {
    final k = e.widget.key;
    if (k is GlobalKey) {
      final existing = _globalElements[k];
      if (existing != null && !identical(existing, e)) {
        throw StateError('Duplicate GlobalKey detected: ${k.value}');
      }
      _globalElements[k] = e;
    }
  }

  void unregisterGlobal(Element e) {
    final k = e.widget.key;
    if (k is GlobalKey) {
      final existing = _globalElements[k];
      if (identical(existing, e)) {
        _globalElements.remove(k);
      }
    }
  }
}

abstract class Element {
  Widget widget;
  final Map<Type, Object> inherited;
  late final BuildOwner owner;
  // Ordered children maintained across rebuilds for unkeyed reconciliation.
  List<Element> _children = const [];
  Map<Key, Element> _childrenByKey = {};
  Map<Key, Element> _nextChildrenByKey = {};
  final Set<Element> _dependents = {};
  // Next-frame children during reconciliation.
  List<Element> _nextChildren = const [];
  int _childIndex = 0;
  bool _depsChanged = false;

  Element(this.widget, this.inherited);

  void mount(BuildOwner owner, Map<Type, Object> map) {
    this.owner = owner;
    didMount();
    owner.registerGlobal(this);
  }

  void didMount() {}

  void performRebuild();

  Iterable<Element> get children => _children;

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
    // Unmount children that were not retained
    final toRemove = <Element>[];
    for (final c in _children) {
      if (!_nextChildren.contains(c)) toRemove.add(c);
    }
    for (final r in toRemove) {
      r.unmount();
    }
    _childrenByKey = _nextChildrenByKey;
    _children = _nextChildren;
  }

  void registerDependent(Element e) {
    _dependents.add(e);
  }

  void notifyDependents() {
    for (final d in _dependents) {
      d._markDependenciesChanged();
      owner.scheduleBuild(d);
    }
  }

  void _markDependenciesChanged() {
    _depsChanged = true;
  }

  void unmount() {
    for (final c in _children) {
      c.unmount();
    }
    owner.unregisterGlobal(this);
    didUnmount();
  }

  void didUnmount() {}
}

class StatelessElement extends Element {
  StatelessElement(super.widget, super.inherited);

  @override
  void performRebuild() {
    beginChildReconcile();
    final ctx = BuildContext.internal(owner.renderContext, inherited,
        owner: owner, parentElement: this);
    final built = widget.buildWidget(ctx);
    if (built == null) {
      // No children
    } else if (built is Fragment) {
      for (final w in built.children) {
        reuseOrInflateChild(w, Map<Type, Object>.from(inherited));
      }
    } else {
      reuseOrInflateChild(built, Map<Type, Object>.from(inherited));
    }
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
    try {
      state.initState();
    } catch (_) {}
  }

  @override
  void didUnmount() {
    // Allow state to clean up
    try {
      state.dispose();
    } catch (_) {}
  }

  @override
  void performRebuild() {
    beginChildReconcile();
    final ctx = BuildContext.internal(owner.renderContext, inherited,
        owner: owner, parentElement: this);
    if (_depsChanged) {
      _depsChanged = false;
      try {
        state.didChangeDependencies();
      } catch (_) {}
    }
    final built = state.buildWidget(ctx);
    if (built == null) {
      // No children
    } else if (built is Fragment) {
      for (final w in built.children) {
        reuseOrInflateChild(w, Map<Type, Object>.from(inherited));
      }
    } else {
      reuseOrInflateChild(built, Map<Type, Object>.from(inherited));
    }
    endChildReconcile();
  }

  @override
  void updateWidget(Widget newWidget) {
    final oldWidget = widget as StatefulWidget;
    widget = newWidget;
    try {
      state.attach(newWidget as StatefulWidget, owner, this);
      state.didUpdateWidget(oldWidget);
    } catch (_) {}
    owner.scheduleBuild(this);
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
    // Prepare inherited with provider entry for dependents
    final inh = Map<Type, Object>.from(inherited);
    final provided = (widget as InheritedWidget).value;
    inh[provided.runtimeType] = InheritedEntry(provided, this);
    final ctx = BuildContext.internal(owner.renderContext, inh,
        owner: owner, parentElement: this);
    final built = (widget as InheritedWidget).buildWidget(ctx);
    if (built == null) {
      // No children
    } else if (built is Fragment) {
      for (final w in built.children) {
        reuseOrInflateChild(w, Map<Type, Object>.from(inh));
      }
    } else {
      reuseOrInflateChild(built, Map<Type, Object>.from(inh));
    }
    endChildReconcile();

    final current = (widget as InheritedWidget).value;
    if ((widget as InheritedWidget).updateShouldNotify(_lastValue)) {
      _lastValue = current;
      notifyDependents();
    }
  }
}
