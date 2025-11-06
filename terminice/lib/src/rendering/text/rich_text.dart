import '../widget.dart';
import '../engine.dart';
import 'utils.dart' as txt;

class TextSpan {
  final String text;
  final String? color; // ANSI color prefix
  final bool bold;
  final List<TextSpan> children;
  const TextSpan(this.text,
      {this.color, this.bold = false, this.children = const []});
}

class RichText extends Widget {
  final TextSpan span;
  final bool withGutter;
  final int? maxWidth; // if null, no wrapping; else wrap to width
  const RichText(this.span, {this.withGutter = true, this.maxWidth});

  @override
  Widget? buildWidget(BuildContext context) {
    final line = _buildLine(context, span);
    final width = maxWidth ?? context.terminalColumns;
    final lines = width > 0 ? txt.wrapAnsi(line, width) : [line];
    final printable = _MultiLinePrintable(lines);
    if (withGutter) {
      return PrintableWidget(_WithGutterPrintable(printable));
    } else {
      return PrintableWidget(printable);
    }
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

class _MultiLinePrintable implements Printable {
  final List<String> lines;
  const _MultiLinePrintable(this.lines);
  @override
  void render(RenderEngine engine) {
    for (final l in lines) {
      engine.writeLine(l);
    }
  }
}

class _WithGutterPrintable implements Printable {
  final Printable inner;
  const _WithGutterPrintable(this.inner);
  @override
  void render(RenderEngine engine) {
    engine.withGutter(() => inner.render(engine));
  }
}
