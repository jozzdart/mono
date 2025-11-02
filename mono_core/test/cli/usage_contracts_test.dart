import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

class SimpleUsageRenderer extends UsageRenderer {
  const SimpleUsageRenderer();

  @override
  String render(CliCommandTree tree) {
    final buffer = StringBuffer();
    void writeCmd(CliCommand cmd, {String indent = ''}) {
      buffer.writeln(
          '$indent${cmd.name}${cmd.description == null ? '' : ' - ${cmd.description}'}');
      for (final sub in cmd.subcommands) {
        writeCmd(sub, indent: '$indent  ');
      }
    }

    buffer.writeln('Usage:');
    writeCmd(tree.root);
    return buffer.toString().trimRight();
  }
}

class SimpleErrorRenderer extends ErrorRenderer {
  const SimpleErrorRenderer();

  @override
  String renderError(String message, {CliCommandTree? tree}) {
    if (tree == null) return 'Error: $message';
    return 'Error: $message\nSee `help` for: ${tree.root.name}';
  }
}

void main() {
  group('UsageRenderer', () {
    test('renders nested command tree', () {
      final tree = CliCommandTree(
        root: CliCommand(
          name: 'mono',
          description: 'Mono repo tool',
          subcommands: [
            CliCommand(name: 'run', description: 'Run tasks'),
            CliCommand(
                name: 'list',
                description: 'List packages',
                subcommands: [
                  CliCommand(name: 'groups'),
                ]),
          ],
        ),
      );

      const renderer = SimpleUsageRenderer();
      final text = renderer.render(tree);
      expect(text, contains('Usage:'));
      expect(text, contains('mono - Mono repo tool'));
      expect(text, contains('  run - Run tasks'));
      expect(text, contains('  list - List packages'));
      expect(text, contains('    groups'));
    });
  });

  group('ErrorRenderer', () {
    test('renders message without tree', () {
      const r = SimpleErrorRenderer();
      expect(r.renderError('bad input'), 'Error: bad input');
    });

    test('renders message with help hint when tree provided', () {
      const r = SimpleErrorRenderer();
      final tree = CliCommandTree(root: CliCommand(name: 'mono'));
      final text = r.renderError('unknown command', tree: tree);
      expect(text, contains('Error: unknown command'));
      expect(text, contains('See `help` for: mono'));
    });
  });
}
