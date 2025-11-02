import 'package:meta/meta.dart';
import 'cli_ast.dart';

@immutable
abstract class CliTokenizer {
  const CliTokenizer();
  List<String> tokenize(String input);
}

@immutable
abstract class CliParser {
  const CliParser();
  CliInvocation parse(List<String> argv, {CliCommandTree? commandTree});
}

@immutable
abstract class ArgsAdapter {
  const ArgsAdapter();
  CliInvocation adapt(dynamic engineResult);
}

// EBNF (spec only):
// selector   := 'all' | group | pkg | glob
// pkg        := NAME
// group      := ':' NAME
// glob       := NAME ('*' | '?')+
// list       := selector (',' selector)*
// invocation := command (WS list)? (WS options)?

