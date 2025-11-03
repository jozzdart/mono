abstract class Renderable {
  const Renderable();
}

class ListRenderable extends Renderable {
  final List<Object> items; // Strings or Renderables
  final bool numbered;
  const ListRenderable(this.items, {this.numbered = false});
}

class TableRenderable extends Renderable {
  final List<String> headers;
  final List<List<Object>> rows; // String/Renderable cells
  const TableRenderable({required this.headers, required this.rows});
}

class Section extends Renderable {
  final String title;
  final bool initiallyCollapsed;
  final List<Object> body; // Strings or Renderables
  const Section(this.title,
      {this.initiallyCollapsed = false, this.body = const []});
}
