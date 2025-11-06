import 'package:terminice/src/style/theme.dart';

import 'context.dart';
import 'core/element.dart' show BuildOwner, Element;
import 'engine.dart';

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
  // New preferred API: return a widget subtree instead of mutating context.
  Widget? buildWidget(BuildContext context) => null;

  // Back-compat API: mutate [context] by adding children. Default adapts
  // [buildWidget] if overridden.
  void build(BuildContext context) {
    final built = buildWidget(context);
    if (built != null) context.widget(built);
  }

  Key? get key => null;

  @override
  void render(RenderEngine engine) {
    _renderWith(engine, const {});
  }

  // Internal hook to render with inherited values.
  void _renderWith(RenderEngine engine, Map<Type, Object> inherited) {
    final b = BuildContext.internal(engine.context, inherited);
    build(b);
    for (final p in b.children) {
      p.render(engine);
    }
  }

  // Public wrapper so other files can invoke a render with inherited values.
  void renderWithInherited(RenderEngine engine, Map<Type, Object> inherited) =>
      _renderWith(engine, inherited);
}

/// Flutter-like base for simple stateless widgets.
abstract class StatelessWidget extends Widget {
  const StatelessWidget();
}

/// BuildContext collects children in a widget's build method and provides
/// convenient accessors to the render context.
class BuildContext {
  final RenderContext renderContext;
  final List<Printable> children;
  final Map<Type, Object> _inherited;
  final BuildOwner? owner;
  final Element? parentElement;

  const BuildContext(
      {required Map<Type, Object> inherited,
      required this.renderContext,
      this.children = const <Printable>[],
      this.owner,
      this.parentElement})
      : _inherited = inherited;

  BuildContext.internal(this.renderContext, Map<Type, Object> inherited,
      {this.owner, this.parentElement})
      : _inherited = Map<Type, Object>.from(inherited),
        children = const <Printable>[];

  int get terminalColumns => renderContext.terminalColumns;
  PromptTheme get theme => renderContext.theme;

  void child(Printable printable) => children.add(printable);
  void addAll(Iterable<Printable> list) => children.addAll(list);

  // Add a widget preserving inherited values
  void widget(Widget widget) {
    if (owner != null && parentElement != null) {
      final el = parentElement!
          .reuseOrInflateChild(widget, Map<Type, Object>.from(_inherited));
      children.add(_ElementPrintable(el, owner!));
    } else {
      children.add(
          _WidgetWithInherited(widget, Map<Type, Object>.from(_inherited)));
    }
  }

  // Inherited lookup and registration
  T? dependOn<T>() {
    final v = _inherited[T];
    if (v is _InheritedEntry) {
      if (parentElement != null) {
        v.provider.registerDependent(parentElement!);
      }
      final val = v.value;
      return val as T?;
    }
    return v is T ? v : null;
  }

  void provide<T>(T value) {
    _inherited[T] = value as Object;
  }

  Map<Type, Object> snapshotInherited() => Map<Type, Object>.from(_inherited);

  // Inherited helpers
  void provideInherited<T>(T value) {
    if (parentElement == null) {
      provide<T>(value);
      return;
    }
    _inherited[T] = _InheritedEntry(value as Object, parentElement!);
  }
}

class _WidgetWithInherited implements Printable {
  final Widget child;
  final Map<Type, Object> inherited;
  const _WidgetWithInherited(this.child, this.inherited);
  @override
  void render(RenderEngine engine) {
    child._renderWith(engine, inherited);
  }
}

class _ElementPrintable implements Printable {
  final Element element;
  final BuildOwner owner;
  const _ElementPrintable(this.element, this.owner);
  @override
  void render(RenderEngine engine) {
    owner.buildDirty();
    for (final p in element.outputs) {
      p.render(engine);
    }
  }
}

class _InheritedEntry {
  final Object value;
  final Element provider;
  const _InheritedEntry(this.value, this.provider);
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
class PrintableWidget extends Widget {
  final Printable printable;
  const PrintableWidget(this.printable);
  @override
  void build(BuildContext context) => context.child(printable);
}

/// Stateful widgets with ephemeral state. setState scheduling is provided by
/// the future AppHost; for now setState only mutates synchronously.
abstract class StatefulWidget extends Widget {
  const StatefulWidget();
  State createState();

  @override
  void render(RenderEngine engine) {
    final inherited = const <Type, Object>{};
    _renderStateful(engine, inherited);
  }

  void _renderStateful(RenderEngine engine, Map<Type, Object> inherited) {
    final ctx = BuildContext.internal(engine.context, inherited);
    final state = createState();
    state.attach(this, null, null);
    state.build(ctx);
    for (final p in ctx.children) {
      p.render(engine);
    }
  }
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
  }

  // New preferred API for State classes; default adapts to [build].
  Widget? buildWidget(BuildContext context) => null;

  // Back-compat API: mutate [context]. Default adapts [buildWidget] if set.
  void build(BuildContext context) {
    final built = buildWidget(context);
    if (built != null) context.widget(built);
  }
}
