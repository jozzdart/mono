import 'dart:io';

import 'package:mono_core/mono_core.dart';

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
    const sep = '────────────────────────────────────────────────────────────';

    final buffer = StringBuffer();

    buffer.writeln(sep);
    for (final line in _logo) {
      buffer.writeln(line);
    }

    buffer.writeln(sep);

    buffer.writeln('Usage');
    buffer.writeln('  mono <command> [targets] [options]');
    buffer.writeln(sep);

    buffer.writeln('Notes');
    buffer.writeln(
        '  - Built-in commands like get run on all packages when no targets are given.');
    buffer.writeln(
        '  - External tasks require explicit targets; use "all" to run on all packages.');
    buffer.writeln(sep);

    buffer.writeln('Commands');
    if (commands.isNotEmpty) {
      final sorted = [...commands]..sort((a, b) => a.name.compareTo(b.name));
      final maxNameLen = sorted
          .map((c) => _displayName(c).length)
          .fold<int>(0, (m, e) => e > m ? e : m);
      for (final c in sorted) {
        final name = _displayName(c);
        final pad = ' ' * (maxNameLen - name.length);
        buffer.writeln('  $name$pad  ${c.description}');
      }
    }

    buffer.writeln(sep);
    buffer.writeln('Global options');
    buffer.writeln('  --[no-]color  --[no-]icons  --[no-]timestamp');
    buffer.writeln(sep);

    stdout.writeln(buffer.toString().trimRight());

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

const _logo = <String>[
  """
                                 
                                 
  __ _  ___  ___  ___ 
 /  ' \\/ _ \\/ _ \\/ _ \\
/_/_/_/\\___/_//_/\\___/
                      
"""
];
