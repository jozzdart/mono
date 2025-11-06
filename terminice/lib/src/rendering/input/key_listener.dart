import '../widget.dart';
import 'focus.dart';
import 'key_events.dart';

/// Base interactive widget that receives key events when focused.
abstract class KeyListenerWidget extends StatefulWidget {
  final Widget child;
  final bool autofocus;
  KeyListenerWidget({required this.child, this.autofocus = true});
}

abstract class KeyListenerState<T extends KeyListenerWidget> extends State<T> {
  bool onKey(KeyEvent ev);

  @override
  Widget? buildWidget(BuildContext context) {
    // Register handler for this element.
    if (context.parentElement != null) {
      FocusManager.instance.register(context.parentElement!, _handle);
      if (widget.autofocus) {
        FocusManager.instance.requestFocus(context.parentElement!);
      }
    }
    return widget.child;
  }

  bool _handle(KeyEvent ev) {
    final handled = onKey(ev);
    return handled;
  }
  @override
  void dispose() {
    final el = element;
    if (el != null) {
      FocusManager.instance.unregister(el);
    }
    super.dispose();
  }
}
