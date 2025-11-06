import '../widget.dart';
import '../widgets.dart';
import '../engine.dart';

class Box extends Widget {
  final int width; // target width in columns
  final Widget child;
  Box({required this.width, required this.child});

  @override
  Widget? buildWidget(BuildContext context) => child;
}

class SizedBox extends Widget {
  final int? width;
  final int? height;
  final Widget? child;
  SizedBox({this.width, this.height, this.child});

  @override
  Widget? buildWidget(BuildContext context) {
    final items = <Widget>[];
    if (height != null && height! > 0) {
      for (int i = 0; i < height!; i++) {
        items.add(PrintableWidget(_BlankLine()));
      }
    }
    if (child != null) items.add(child!);
    if (items.isEmpty) return null;
    return Column(items);
  }
}

class _BlankLine implements Printable {
  @override
  void render(RenderEngine engine) => engine.writeLine('');
}
