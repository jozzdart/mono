import '../widget.dart';

/// A minimal navigation stack that renders only the top-most page.
///
/// Descendants can access the navigator via `Navigator.of(context)`
/// to perform push/pop operations.
class Navigator extends StatefulWidget {
  final Widget initial;
  Navigator({required this.initial});

  static NavigatorState of(BuildContext context) {
    final state = context.dependOn<NavigatorState>();
    if (state == null) {
      throw StateError('Navigator.of(context) called with no Navigator above');
    }
    return state;
  }

  @override
  State createState() => NavigatorState();

  // Satisfy the TerminalWidget API; actual building happens in the associated
  // NavigatorState via StatefulWidget.render.
  @override
  void build(BuildContext context) {}
}

class NavigatorState extends State<Navigator> {
  late List<Widget> _stack;
  bool _initialized = false;

  void _ensureInit() {
    if (_initialized) return;
    _stack = [widget.initial];
    _initialized = true;
  }

  /// Push a new page onto the stack.
  void push(Widget page) {
    _ensureInit();
    setState(() {
      _stack.add(page);
    });
  }

  /// Pop the top page. Returns true if a page was popped.
  bool pop() {
    _ensureInit();
    if (_stack.length <= 1) return false;
    setState(() {
      _stack.removeLast();
    });
    return true;
  }

  /// Replace the top page with a new one.
  void replace(Widget page) {
    _ensureInit();
    setState(() {
      if (_stack.isEmpty) {
        _stack.add(page);
      } else {
        _stack[_stack.length - 1] = page;
      }
    });
  }

  /// Returns the current top page.
  Widget get top {
    _ensureInit();
    return _stack.last;
  }

  @override
  void build(BuildContext context) {
    _ensureInit();
    // Expose this state to descendants for Navigator.of(context).
    context.provideInherited<NavigatorState>(this);
    // Render only the top-most page.
    context.widget(_stack.last);
  }
}
