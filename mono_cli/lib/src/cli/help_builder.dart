import 'package:mono_core/mono_core.dart';

/// Builds help text from a list of registered commands with an optional header.
class DefaultHelpBuilder {
  const DefaultHelpBuilder();

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
