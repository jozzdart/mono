import 'package:mono_core_logger/mono_core_logger.dart';

class CodeBlockRenderable extends Renderable {
  final String code;
  final String? language;
  const CodeBlockRenderable(this.code, {this.language});
}
