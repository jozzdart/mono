import 'widget.dart';
import 'widgets.dart';

class ListView extends Widget {
  final List<Widget> children;
  final Widget? separator;
  ListView({required this.children, this.separator});

  @override
  Widget? buildWidget(BuildContext context) {
    if (children.isEmpty) return null;
    final items = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (separator != null && i < children.length - 1) {
        items.add(separator!);
      }
    }
    return Column(children: items);
  }
}
