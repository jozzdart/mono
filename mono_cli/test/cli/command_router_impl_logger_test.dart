import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

// A simple test command for testing
class _TestCommand extends Command {
  const _TestCommand({
    required this.name,
  });

  @override
  final String name;

  @override
  List<String> get aliases => const [];

  @override
  String get description => 'Test command';

  @override
  Future<int> run(CliContext context) async {
    return 0;
  }
}

void main() {
  group('DefaultCommandRouter', () {
    test('getCommand returns correct command for routing', () {
      final cmd1 = const _TestCommand(name: 'cmd1');
      final cmd2 = const _TestCommand(name: 'cmd2');
      final helpCommand = const _TestCommand(name: 'help');
      final fallbackCommand = const _TestCommand(name: 'fallback');
      final router = DefaultCommandRouter(
        commands: [cmd1, cmd2],
        helpCommand: helpCommand,
        fallbackCommand: fallbackCommand,
      );

      // Test that commands are correctly retrieved
      expect(router.getCommand(const CliInvocation(commandPath: ['cmd1'])),
          same(cmd1));
      expect(router.getCommand(const CliInvocation(commandPath: ['cmd2'])),
          same(cmd2));
      expect(router.getCommand(const CliInvocation(commandPath: [])),
          same(helpCommand));
      expect(router.getCommand(const CliInvocation(commandPath: ['unknown'])),
          same(fallbackCommand));
    });
  });
}
