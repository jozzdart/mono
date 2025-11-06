import '../widget.dart';
import '../modifiers.dart';
import '../engine.dart';

class EdgeInsets {
  final int left, top, right, bottom;
  const EdgeInsets._(this.left, this.top, this.right, this.bottom);
  const EdgeInsets.all(int v) : this._(v, v, v, v);
  const EdgeInsets.symmetric({int horizontal = 0, int vertical = 0})
      : this._(horizontal, vertical, horizontal, vertical);
}

class Padding extends Widget {
  final EdgeInsets padding;
  final Widget child;
  Padding({required this.padding, required this.child});

  @override
  void build(BuildContext context) {
    for (int i = 0; i < padding.top; i++) {
      context.child(_BlankLine());
    }
    context.child(ModifierScopePrintable(
        (e) => LeftPaddingModifier(padding.left),
        child,
        context.snapshotInherited()));
    for (int i = 0; i < padding.bottom; i++) {
      context.child(_BlankLine());
    }
  }
}

class _BlankLine implements Printable {
  @override
  void render(RenderEngine engine) => engine.writeLine('');
}
