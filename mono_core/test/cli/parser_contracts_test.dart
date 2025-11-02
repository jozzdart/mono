import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

class FakeTokenizer extends CliTokenizer {
  const FakeTokenizer();

  @override
  List<String> tokenize(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return const [];
    return trimmed.split(RegExp(r'\s+'));
  }
}

class FakeParser extends CliParser {
  const FakeParser();

  @override
  CliInvocation parse(List<String> argv, {CliCommandTree? commandTree}) {
    // For test purposes, just echo argv as the commandPath
    return CliInvocation(commandPath: argv);
  }
}

class FakeArgsAdapter extends ArgsAdapter {
  const FakeArgsAdapter();

  @override
  CliInvocation adapt(dynamic engineResult) {
    if (engineResult is Map<String, Object?>) {
      final path = (engineResult['path'] as List<dynamic>? ?? const <dynamic>[])
          .cast<String>();
      final pos = (engineResult['pos'] as List<dynamic>? ?? const <dynamic>[])
          .cast<String>();
      final rawOpts =
          (engineResult['opts'] as Map<Object?, Object?>? ?? const {});
      final opts = <String, List<String>>{};
      for (final entry in rawOpts.entries) {
        opts[entry.key as String] =
            (entry.value as List<dynamic>).cast<String>();
      }
      return CliInvocation(commandPath: path, options: opts, positionals: pos);
    }
    return const CliInvocation(commandPath: []);
  }
}

void main() {
  group('CliTokenizer', () {
    test('splits by whitespace and trims', () {
      const t = FakeTokenizer();
      expect(t.tokenize(''), isEmpty);
      expect(t.tokenize('  '), isEmpty);
      expect(t.tokenize('a b  c'), ['a', 'b', 'c']);
      expect(t.tokenize('  mono   run   test  '), ['mono', 'run', 'test']);
    });
  });

  group('CliParser', () {
    test('parse echoes argv into CliInvocation.commandPath', () {
      const p = FakeParser();
      final inv = p.parse(['mono', 'run']);
      expect(inv.commandPath, ['mono', 'run']);
    });

    test('parse accepts optional commandTree parameter', () {
      const p = FakeParser();
      final tree = CliCommandTree(root: CliCommand(name: 'root'));
      final inv = p.parse(['root'], commandTree: tree);
      expect(inv.commandPath, ['root']);
    });
  });

  group('ArgsAdapter', () {
    test('adapts engine map into CliInvocation', () {
      const a = FakeArgsAdapter();
      final inv = a.adapt({
        'path': ['mono', 'test'],
        'pos': ['pkg:core'],
        'opts': {
          'tag': ['fast', 'unit']
        },
      });
      expect(inv.commandPath, ['mono', 'test']);
      expect(inv.positionals, ['pkg:core']);
      expect(inv.options, containsPair('tag', ['fast', 'unit']));
    });

    test('unknown engine result yields empty invocation', () {
      const a = FakeArgsAdapter();
      final inv = a.adapt('not-a-map');
      expect(inv.commandPath, isEmpty);
      expect(inv.options, isEmpty);
      expect(inv.positionals, isEmpty);
    });
  });
}
