import '../renderables.dart';

class CodeBlockRenderable extends Renderable {
  final String code;
  final String? language;
  const CodeBlockRenderable(this.code, {this.language});
}
