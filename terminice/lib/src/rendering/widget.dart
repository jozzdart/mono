import 'package:terminice/src/style/theme.dart';

import 'context.dart';
import 'core/element.dart' show BuildOwner, Element;
import 'engine.dart';
import 'scheduler.dart';
import 'render/widgets.dart' as ro;
import 'render/adapters.dart';
import 'render/object.dart';

/// Printable describes anything that can render itself to the terminal
/// when provided a [RenderEngine].
abstract class Printable {
  const Printable();
  void render(RenderEngine engine);
}

/// Base class for terminal widgets. Widgets are pure builders: given a
/// [RenderContext], they construct a list of [Printable] children that the
/// renderer executes depth-first.
abstract class Widget implements Printable {
  const Widget();
  // Pure API: return the widget subtree for this node.
  Widget? buildWidget(BuildContext context) => null;

  Key? get key => null;

  @override
  void render(RenderEngine engine) {
    renderWithInherited(engine, const <Type, Object>{});
  }

  // Render this widget subtree by mounting a temporary element tree and
  // collecting printable leaves.
  void renderWithInherited(RenderEngine engine, Map<Type, Object> inherited) {
    final owner = BuildOwner(engine.context);
    final el = owner.inflateWidget(this, inherited);
    el.mount(owner, inherited);
    owner.scheduleBuild(el);
    owner.buildDirty();
    final out = <Printable>[];
    _collectPrintables(el, out);
    for (final p in out) {
      p.render(engine);
    }
  }
}

/// Flutter-like base for simple stateless widgets.
abstract class StatelessWidget extends Widget {
  const StatelessWidget();
}

/// BuildContext collects children in a widget's build method and provides
/// convenient accessors to the render context.
class BuildContext {
  final RenderContext renderContext;
  final Map<Type, Object> _inherited;
  final BuildOwner? owner;
  final Element? parentElement;

  const BuildContext(
      {required Map<Type, Object> inherited,
      required this.renderContext,
      this.owner,
      this.parentElement})
      : _inherited = inherited;

  BuildContext.internal(this.renderContext, Map<Type, Object> inherited,
      {this.owner, this.parentElement})
      : _inherited = Map<Type, Object>.from(inherited);

  int get terminalColumns => renderContext.terminalColumns;
  PromptTheme get theme => renderContext.theme;

  // Inherited lookup and registration
  T? dependOn<T>() {
    final v = _inherited[T];
    if (v is InheritedEntry) {
      if (parentElement != null) {
        v.provider.registerDependent(parentElement!);
      }
      final val = v.value;
      return val as T?;
    }
    return v is T ? v : null;
  }

  Map<Type, Object> snapshotInherited() => Map<Type, Object>.from(_inherited);
}

// Removed old Printable adapters based on mutating BuildContext.

class InheritedEntry {
  final Object value;
  final Element provider;
  const InheritedEntry(this.value, this.provider);
}

/// Identity key for widgets; future use with stateful/app host.
class Key {
  final String value;
  const Key(this.value);
  @override
  String toString() => 'Key($value)';
  @override
  bool operator ==(Object other) => other is Key && other.value == value;
  @override
  int get hashCode => value.hashCode;
}

class LocalKey extends Key {
  const LocalKey(super.value);
}

class GlobalKey extends Key {
  const GlobalKey(super.value);
}

/// Adapter: wrap a [Printable] so it can appear as a [Widget].
class PrintableWidget extends ro.LeafRenderObjectWidget {
  final Printable printable;
  const PrintableWidget(this.printable);
  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderPrintableBox(context.renderContext, printable);
}

/// Stateful widgets with ephemeral state. setState scheduling is provided by
/// the future AppHost; for now setState only mutates synchronously.
abstract class StatefulWidget extends Widget {
  const StatefulWidget();
  State createState();
}

abstract class State<T extends StatefulWidget> {
  late T widget;

  BuildContext? context;
  BuildOwner? _owner;
  Element? _element;

  void attach(T widget, BuildOwner? owner, Element? element) {
    this.widget = widget;
    _owner = owner;
    _element = element;
  }

  void setState(void Function() fn) {
    fn();
    if (_owner != null && _element != null) {
      _owner!.scheduleBuild(_element!);
    }
    AppFramePump.instance.request();
  }

  // Pure API for State classes.
  Widget? buildWidget(BuildContext context) => null;

  void dispose() {}

  void initState() {}

  void didUpdateWidget(covariant T oldWidget) {}

  void didChangeDependencies() {}

  Element? get element => _element;
}

/// Fragment groups multiple children without additional semantics.
class Fragment extends Widget {
  final List<Widget> children;
  const Fragment(this.children);
}

void _collectPrintables(Element element, List<Printable> out) {
  final w = element.widget;
  if (w is PrintableWidget) {
    out.add(w.printable);
    return;
  }
  for (final c in element.children) {
    _collectPrintables(c, out);
  }
}
