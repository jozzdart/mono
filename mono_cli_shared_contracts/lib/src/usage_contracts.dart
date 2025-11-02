import 'package:meta/meta.dart';
import 'cli_ast.dart';

@immutable
abstract class UsageRenderer {
  const UsageRenderer();
  String render(CliCommandTree tree);
}

@immutable
abstract class ErrorRenderer {
  const ErrorRenderer();
  String renderError(String message, {CliCommandTree? tree});
}

