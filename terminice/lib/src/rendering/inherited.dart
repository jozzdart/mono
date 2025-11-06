import '../style/theme.dart';
import 'engine.dart';
import 'widget.dart';

/// Base class for inherited data widgets.
abstract class InheritedWidget extends Widget {
  final Widget child;
  InheritedWidget(this.child);

  /// The stored value. Subclasses should override with a typed value.
  Object get value;

  /// Whether dependents should be notified when the value changes.
  bool updateShouldNotify(Object? oldValue) => oldValue != value;

  @override
  Widget? buildWidget(BuildContext context) => child;
}

/// Theme wrapper providing PromptTheme via inherited lookup.
class Theme extends InheritedWidget {
  final PromptTheme data;
  Theme({required this.data, required Widget child}) : super(child);

  static PromptTheme of(BuildContext context) {
    final v = context.dependOn<PromptTheme>();
    return v ?? context.theme;
  }

  @override
  Object get value => data;
}

/// Applies a default text transform to descendants.
class DefaultTextStyle extends InheritedWidget {
  final String Function(String) apply;
  DefaultTextStyle({required this.apply, required Widget child}) : super(child);

  static String Function(String)? of(BuildContext context) =>
      context.dependOn<String Function(String)>();

  @override
  Object get value => apply;
}

/// Enables gutter on all descendant lines.
class GutterScope extends Widget {
  final Widget child;
  GutterScope(this.child);

  @override
  Widget? buildWidget(BuildContext context) {
    return PrintableWidget(
        _GutterScopePrintable(child, context.snapshotInherited()));
  }
}

class _GutterScopePrintable implements Printable {
  final Widget child;
  final Map<Type, Object> inherited;
  _GutterScopePrintable(this.child, this.inherited);
  @override
  void render(RenderEngine engine) {
    engine.withGutter(() => child.renderWithInherited(engine, inherited));
  }
}
