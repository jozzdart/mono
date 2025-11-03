import 'package:mono_core/mono_core.dart';

const String _helpHeader = 'mono - Manage Dart/Flutter monorepos\n\n'
    'Usage:\n'
    '  mono <command> [targets] [options]\n\n'
    'Notes:\n'
    '- Built-in commands like get run on all packages when no targets are given.\n'
    '- External tasks require explicit targets; use "all" to run on all packages.';

class HelpCommand extends Command {
  const HelpCommand();

  @override
  String get name => 'help';

  @override
  String get description => 'Show usage instructions';

  @override
  Future<int> run(
    CliContext context,
  ) async {
    final router = context.router;
    final commands = router.getAllCommands();
    final helpText = build(commands, header: _helpHeader);
    final logger = context.logger;
    logger.log(helpText);
    return 0;
  }

  String build(List<Command> commands, {String? header}) {
    final buffer = StringBuffer();
    if (header != null && header.isNotEmpty) {
      buffer.writeln(header.trimRight());
    }
    if (commands.isEmpty) return buffer.toString();

    // Sort commands by primary name; aliases are shown inline.
    final sorted = [...commands]..sort((a, b) => a.name.compareTo(b.name));
    final maxNameLen = sorted
        .map((c) => _displayName(c).length)
        .fold<int>(0, (m, e) => e > m ? e : m);

    buffer.writeln('Commands:');
    for (final c in sorted) {
      final name = _displayName(c);
      final pad = ' ' * (maxNameLen - name.length);
      buffer.writeln('  $name$pad  ${c.description}');
    }
    return buffer.toString().trimRight();
  }

  String _displayName(Command c) {
    if (c.aliases.isEmpty) return c.name;
    final aliasStr = c.aliases.join(', ');
    return '${c.name} ($aliasStr)';
  }
}
