import '../widget.dart';

class Wrap extends Widget {
  final List<Widget> children;
  final int spacing;
  Wrap({required this.children, this.spacing = 1});

  @override
  Widget? buildWidget(BuildContext context) => Fragment(children);
}
