import '../context.dart';
import 'buffer.dart';

class PaintContext {
  final RenderContext renderContext;
  final TerminalFrameBuffer buffer;
  PaintContext(this.renderContext, this.buffer);

  void writeLine(String line) {
    buffer.addLine(line);
  }
}


