import 'widget.dart';
import 'engine.dart';
import 'widgets.dart';

class TableColumn {
  final int? width; // fixed width; null = auto
  TableColumn({this.width});
}

class TableView extends Widget {
  final List<TableColumn> columns;
  final List<List<Widget>> rows;

  TableView({required this.columns, required this.rows});

  @override
  Widget? buildWidget(BuildContext context) {
    final sep = '${context.theme.gray}│${context.theme.reset}';
    final widgets = <Widget>[];
    for (final r in rows) {
      for (int i = 0; i < r.length; i++) {
        widgets.add(r[i]);
        if (i < r.length - 1) {
          widgets.add(PrintableWidget(_TextLinePrintable(sep)));
        }
      }
    }
    return Column(children: widgets);
  }
}

class _TextLinePrintable implements Printable {
  final String text;
  _TextLinePrintable(this.text);
  @override
  void render(RenderEngine engine) => engine.writeLine(text);
}
