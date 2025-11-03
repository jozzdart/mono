import '../renderables.dart';

class DiffLine {
  final String text;
  final DiffOp op;
  const DiffLine(this.text, this.op);
}

enum DiffOp { context, add, remove }

class DiffRenderable extends Renderable {
  final String? leftLabel;
  final String? rightLabel;
  final List<DiffLine> lines;
  const DiffRenderable(
      {this.leftLabel, this.rightLabel, this.lines = const <DiffLine>[]});
}
