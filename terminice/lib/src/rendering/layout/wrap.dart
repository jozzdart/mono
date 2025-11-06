import '../widget.dart';

class Wrap extends Widget {
  final List<Widget> children;
  final int spacing;
  Wrap({required this.children, this.spacing = 1});

  @override
  void build(BuildContext context) {
    for (int i = 0; i < children.length; i++) {
      context.widget(children[i]);
    }
  }
}
