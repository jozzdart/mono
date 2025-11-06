import 'package:terminice/src/rendering/src.dart';

class TextInput extends KeyListenerWidget {
  final void Function(String value)? onUpdated;
  final void Function(String value)? onSubmitted;

  TextInput({this.onUpdated, this.onSubmitted, super.autofocus})
      : super(child: _Empty());

  @override
  State createState() => _TextInputState();

  @override
  void build(BuildContext context) {}
}

class _TextInputState extends KeyListenerState<TextInput> {
  String _value = '';

  @override
  bool onKey(KeyEvent ev) {
    switch (ev.type) {
      case KeyEventType.char:
        final ch = ev.char ?? '';
        if (ch.isEmpty) return false;
        setState(() {
          _value += ch;
        });
        widget.onUpdated?.call(_value);
        return true;
      case KeyEventType.space:
        setState(() {
          _value += ' ';
        });
        widget.onUpdated?.call(_value);
        return true;
      case KeyEventType.backspace:
        if (_value.isEmpty) return true;
        setState(() {
          _value = _value.substring(0, _value.length - 1);
        });
        widget.onUpdated?.call(_value);
        return true;
      case KeyEventType.enter:
        widget.onSubmitted?.call(_value);
        return true;
      default:
        return false;
    }
  }

  bool _handle(KeyEvent ev) => onKey(ev);

  @override
  void build(BuildContext context) {
    if (context.parentElement != null) {
      FocusManager.instance.register(context.parentElement!, _handle);
      if (widget.autofocus) {
        FocusManager.instance.requestFocus(context.parentElement!);
      }
    }
    context.widget(Text(_value));
  }
}

class _Empty extends StatelessWidget {
  _Empty();
  @override
  void build(BuildContext context) {}
}
