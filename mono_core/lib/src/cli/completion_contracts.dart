import 'package:meta/meta.dart';

@immutable
class CompletionContext {
  const CompletionContext({required this.line, required this.cursor});
  final String line;
  final int cursor;
}

@immutable
class CompletionItem {
  const CompletionItem({required this.value, this.description});
  final String value;
  final String? description;
}

@immutable
abstract class CompletionProvider {
  const CompletionProvider();
  List<CompletionItem> suggest(CompletionContext context);
}

