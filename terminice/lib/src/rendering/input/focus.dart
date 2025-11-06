import '../core/element.dart';
import '../widget.dart';
import 'key_events.dart';

typedef KeyHandler = bool Function(KeyEvent ev);

class FocusManager {
  static final FocusManager instance = FocusManager._();
  FocusManager._();

  Element? _focused;
  final Map<Element, KeyHandler> _handlers = {};

  void register(Element element, KeyHandler handler) {
    _handlers[element] = handler;
  }

  void unregister(Element element) {
    _handlers.remove(element);
    if (_focused == element) _focused = null;
  }

  void requestFocus(Element element) {
    _focused = element;
  }

  void clearFocus() {
    _focused = null;
  }

  /// Dispatches to the focused element's handler. Returns true if handled.
  bool dispatch(KeyEvent ev) {
    final e = _focused;
    if (e == null) return false;
    final h = _handlers[e];
    if (h == null) return false;
    return h(ev);
  }
}

/// Focus widget requests focus for its own element at build time and renders
/// its child. Useful to explicitly set focus in a subtree.
class Focus extends StatelessWidget {
  final Widget child;
  final bool requestOnBuild;
  Focus({required this.child, this.requestOnBuild = true});

  @override
  void build(BuildContext context) {
    if (requestOnBuild && context.parentElement != null) {
      FocusManager.instance.requestFocus(context.parentElement!);
    }
    context.widget(child);
  }
}
