import '../widget.dart';
import '../render/widgets.dart' as ro;
import '../render/box.dart' as rbox;
import '../render/object.dart';

class TextSpan {
  final String text;
  final String? color; // ANSI color prefix
  final bool bold;
  final List<TextSpan> children;
  const TextSpan(this.text,
      {this.color, this.bold = false, this.children = const []});
}

class RichText extends ro.LeafRenderObjectWidget {
  final TextSpan span;
  final bool withGutter;
  final int? maxWidth; // if null, no wrapping; else wrap to width
  const RichText(this.span, {this.withGutter = true, this.maxWidth});

  @override
  RenderObject createRenderObject(BuildContext context) {
    final line = _buildLine(context, span);
    return rbox.RenderParagraph(line);
  }

  String _buildLine(BuildContext context, TextSpan span) {
    final buf = StringBuffer();
    void writeSpan(TextSpan s) {
      final prefix = '${s.bold ? context.theme.bold : ''}${s.color ?? ''}';
      final suffix = prefix.isNotEmpty ? context.theme.reset : '';
      buf.write('$prefix${s.text}$suffix');
      for (final c in s.children) {
        writeSpan(c);
      }
    }

    writeSpan(span);
    return buf.toString();
  }
}

// Removed legacy printable helpers; rendering handled by RenderParagraph
