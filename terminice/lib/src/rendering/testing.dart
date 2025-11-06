import 'engine.dart';
import 'widget.dart';
import 'context.dart';

/// TestRenderer captures output lines into a buffer for assertions.
class TestRenderer {
  final List<String> lines = [];

  void render(Widget root, {required RenderContext context}) {
    final engine =
        RenderEngine(context: context, write: (line) => lines.add(line));
    root.render(engine);
  }
}
