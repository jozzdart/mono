import '../widget.dart';
import '../widgets.dart';
import '../engine.dart';

enum Axis { horizontal, vertical }

enum MainAxisAlignment { start, center, end, spaceBetween }

enum CrossAxisAlignment { start, center, end, stretch }

/// Minimal Flex that just sequences children; sizing is handled by children.
class Flex extends Widget {
  final Axis direction;
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const Flex({
    required this.direction,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget? buildWidget(BuildContext context) {
    // For terminal line rendering, both directions are rendered sequentially.
    // A future inline composer can replace this with true horizontal layout.
    if (children.isEmpty) return null;
    return Column(children: children);
  }
}

class Row extends Flex {
  final int spacing;
  const Row({
    required super.children,
    super.mainAxisAlignment,
    super.crossAxisAlignment,
    this.spacing = 0,
  }) : super(direction: Axis.horizontal);
}

class ColumnFlex extends Flex {
  final int spacing;
  const ColumnFlex({
    required super.children,
    super.mainAxisAlignment,
    super.crossAxisAlignment,
    this.spacing = 0,
  }) : super(direction: Axis.vertical);

  @override
  Widget? buildWidget(BuildContext context) {
    if (children.isEmpty) return null;
    final items = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1 && spacing > 0) {
        for (int s = 0; s < spacing; s++) {
          items.add(PrintableWidget(_BlankLine()));
        }
      }
    }
    return Column(children: items);
  }
}

class Spacer extends Widget {
  final int spaces;
  const Spacer({this.spaces = 1});
  @override
  Widget? buildWidget(BuildContext context) =>
      PrintableWidget(_SpacerPrintable(spaces));
}

class _SpacerPrintable implements Printable {
  final int spaces;
  const _SpacerPrintable(this.spaces);
  @override
  void render(RenderEngine engine) {
    engine.writeLine(' ' * spaces);
  }
}

class _BlankLine implements Printable {
  const _BlankLine();
  @override
  void render(RenderEngine engine) => engine.writeLine('');
}
