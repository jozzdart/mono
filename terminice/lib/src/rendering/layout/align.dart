import '../widget.dart';
import '../modifiers.dart';

enum Alignment { left, center, right }

class Align extends Widget {
  final Alignment alignment;
  final Widget child;
  Align({required this.alignment, required this.child});

  @override
  void build(BuildContext context) {
    final mode = switch (alignment) {
      Alignment.left => AlignMode.left,
      Alignment.center => AlignMode.center,
      Alignment.right => AlignMode.right,
    };
    context.child(ModifierScopePrintable(
        (e) => AlignModifier(context.terminalColumns, mode),
        child,
        context.snapshotInherited()));
  }
}
