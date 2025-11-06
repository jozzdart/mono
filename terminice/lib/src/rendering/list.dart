import 'widget.dart';

class ListView extends Widget {
  final List<Widget> children;
  final Widget? separator;
  ListView({required this.children, this.separator});

  @override
  void build(BuildContext context) {
    for (int i = 0; i < children.length; i++) {
      context.widget(children[i]);
      if (separator != null && i < children.length - 1) {
        context.widget(separator!);
      }
    }
  }
}
