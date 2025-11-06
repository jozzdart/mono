import 'widget.dart';
import 'engine.dart';

class TableColumn {
  final int? width; // fixed width; null = auto
  TableColumn({this.width});
}

class TableView extends Widget {
  final List<TableColumn> columns;
  final List<List<Widget>> rows;

  TableView({required this.columns, required this.rows});

  @override
  void build(BuildContext context) {
    // Minimal: render each row cells separated by a vertical bar glyph.
    final sep = '${context.theme.gray}│${context.theme.reset}';
    for (final r in rows) {
      for (int i = 0; i < r.length; i++) {
        context.widget(r[i]);
        if (i < r.length - 1) {
          context.child(_TextLinePrintable(sep));
        }
      }
    }
  }
}

class _TextLinePrintable implements Printable {
  final String text;
  _TextLinePrintable(this.text);
  @override
  void render(RenderEngine engine) => engine.writeLine(text);
}
