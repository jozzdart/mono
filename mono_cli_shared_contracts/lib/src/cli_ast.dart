import 'package:meta/meta.dart';
import 'package:mono_selector_contracts/mono_selector_contracts.dart';

@immutable
class CliCommandTree {
  const CliCommandTree({required this.root});
  final CliCommand root;
}

@immutable
class CliCommand {
  const CliCommand({
    required this.name,
    this.description,
    this.options = const [],
    this.arguments = const [],
    this.subcommands = const [],
  });
  final String name;
  final String? description;
  final List<CliOption> options;
  final List<CliArgument> arguments;
  final List<CliCommand> subcommands;
}

@immutable
class CliOption {
  const CliOption({
    required this.name,
    this.short,
    this.help,
    this.takesValue = true,
    this.multiple = false,
  });
  final String name;
  final String? short;
  final String? help;
  final bool takesValue;
  final bool multiple;
}

@immutable
class CliArgument {
  const CliArgument({required this.name, this.help, this.optional = true, this.multiple = false});
  final String name;
  final String? help;
  final bool optional;
  final bool multiple;
}

@immutable
class CliInvocation {
  const CliInvocation({required this.commandPath, this.options = const {}, this.positionals = const [], this.targets = const []});
  final List<String> commandPath;
  final Map<String, List<String>> options; // normalized long-name -> values
  final List<String> positionals;
  final List<TargetExpr> targets; // parsed/normalized target expressions
}

