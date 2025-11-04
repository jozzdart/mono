import 'package:mono_cli/mono_cli.dart';
import 'package:test/test.dart';
import 'package:mono_core/mono_core.dart';

void main() {
  group('ArgsTokenizer', () {
    const tokenizer = ArgsTokenizer();

    test('empty input yields empty list', () {
      expect(tokenizer.tokenize(''), isEmpty);
      expect(tokenizer.tokenize('   '), isEmpty);
      expect(tokenizer.tokenize('\n\t  '), isEmpty);
    });

    test('splits by any whitespace and trims', () {
      expect(tokenizer.tokenize('a b   c'), ['a', 'b', 'c']);
      expect(
          tokenizer.tokenize('  one\t two\nthree  '), ['one', 'two', 'three']);
    });

    test('does not handle quotes/escaping (documented naive split)', () {
      expect(tokenizer.tokenize('"a b" c'), ['"a', 'b"', 'c']);
      expect(tokenizer.tokenize("a 'b c' d"), ['a', "'b", "c'", 'd']);
    });
  });

  group('ArgsCliParser', () {
    const parser = ArgsCliParser();

    CliInvocation parse(List<String> argv) => parser.parse(argv);

    test('empty argv maps to implicit help command', () {
      final inv = parse([]);
      expect(inv.commandPath, ['help']);
      expect(inv.options, isEmpty);
      expect(inv.positionals, isEmpty);
      expect(inv.targets, isEmpty);
    });

    test('single command without args', () {
      final inv = parse(['list']);
      expect(inv.commandPath, ['list']);
      expect(inv.options, isEmpty);
      expect(inv.positionals, isEmpty);
      expect(inv.targets, isEmpty);
    });

    group('options parsing', () {
      test('--concurrency and -j are captured as strings', () {
        final a = parse(['run', '--concurrency', '4']);
        expect(a.options['concurrency'], ['4']);

        final b = parse(['run', '-j', '8']);
        expect(b.options['concurrency'], ['8']);
      });

      test('--order captured as string', () {
        final inv = parse(['run', '--order', 'topo']);
        expect(inv.options['order'], ['topo']);
      });

      test('flags --dry-run and --check only included when true', () {
        final inv = parse(['exec', '--dry-run', '--check']);
        expect(inv.options['dry-run'], ['true']);
        expect(inv.options['check'], ['true']);

        final inv2 = parse(['exec']);
        expect(inv2.options.containsKey('dry-run'), isFalse);
        expect(inv2.options.containsKey('check'), isFalse);
      });

      test('multi-option --targets/-t aggregates multiple occurrences', () {
        final inv = parse([
          'run',
          '--targets',
          'a',
          '--targets',
          'b',
          '-t',
          'c',
          '-t',
          'd',
        ]);
        expect(inv.options['targets'], ['a', 'b', 'c', 'd']);
      });

      test('pretty flags are only included when explicitly provided', () {
        final inv = parse(['run']);
        expect(inv.options.containsKey('color'), isFalse);
        expect(inv.options.containsKey('icons'), isFalse);
        expect(inv.options.containsKey('timestamp'), isFalse);
      });

      test('--color/--no-color captured as true/false', () {
        final inv1 = parse(['run', '--color']);
        expect(inv1.options['color'], ['true']);
        final inv2 = parse(['run', '--no-color']);
        expect(inv2.options['color'], ['false']);
      });

      test('--icons/--no-icons captured as true/false', () {
        final inv1 = parse(['run', '--icons']);
        expect(inv1.options['icons'], ['true']);
        final inv2 = parse(['run', '--no-icons']);
        expect(inv2.options['icons'], ['false']);
      });

      test('--timestamp/--no-timestamp captured as true/false', () {
        final inv1 = parse(['run', '--timestamp']);
        expect(inv1.options['timestamp'], ['true']);
        final inv2 = parse(['run', '--no-timestamp']);
        expect(inv2.options['timestamp'], ['false']);
      });
    });

    group('positionals and targets parsing', () {
      test('packages, groups, globs, and all', () {
        final inv = parse(['run', 'pkg1', ':groupA', 'glob*', 'all']);

        // Positionals are preserved as provided
        expect(inv.positionals, ['pkg1', ':groupA', 'glob*', 'all']);

        // Targets are normalized and typed
        expect(inv.targets.length, 4);
        expect(inv.targets[0], isA<TargetPackage>());
        expect((inv.targets[0] as TargetPackage).name, 'pkg1');
        expect(inv.targets[1], isA<TargetGroup>());
        expect((inv.targets[1] as TargetGroup).groupName, 'groupA');
        expect(inv.targets[2], isA<TargetGlob>());
        expect((inv.targets[2] as TargetGlob).pattern, 'glob*');
        expect(inv.targets[3], isA<TargetAll>());
      });

      test('comma-separated selectors are split and trimmed', () {
        final inv = parse(['run', 'pkg1,:g1,glob*', 'all', ':g2', ',,,pkg2,,']);

        // Positionals remain unsplit
        expect(inv.positionals, ['pkg1,:g1,glob*', 'all', ':g2', ',,,pkg2,,']);

        // Targets flatten and ignore empty tokens
        expect(inv.targets.length, 6);

        expect(inv.targets[0], isA<TargetPackage>());
        expect((inv.targets[0] as TargetPackage).name, 'pkg1');

        expect(inv.targets[1], isA<TargetGroup>());
        expect((inv.targets[1] as TargetGroup).groupName, 'g1');

        expect(inv.targets[2], isA<TargetGlob>());
        expect((inv.targets[2] as TargetGlob).pattern, 'glob*');

        expect(inv.targets[3], isA<TargetAll>());

        expect(inv.targets[4], isA<TargetGroup>());
        expect((inv.targets[4] as TargetGroup).groupName, 'g2');

        expect(inv.targets[5], isA<TargetPackage>());
        expect((inv.targets[5] as TargetPackage).name, 'pkg2');
      });
    });

    test('allows trailing options interspersed with positionals', () {
      final inv = parse(['run', 'pkg1', '--check', 'pkg2', '-j', '2']);

      // Options parsed regardless of position
      expect(inv.options['check'], ['true']);
      expect(inv.options['concurrency'], ['2']);

      // Positionals preserved order
      expect(inv.positionals, ['pkg1', 'pkg2']);

      // Targets inferred from positionals
      expect(inv.targets.length, 2);
      expect(inv.targets[0], isA<TargetPackage>());
      expect((inv.targets[0] as TargetPackage).name, 'pkg1');
      expect(inv.targets[1], isA<TargetPackage>());
      expect((inv.targets[1] as TargetPackage).name, 'pkg2');
    });

    test('unknown option throws a FormatException', () {
      expect(() => parse(['run', '--nope']), throwsA(isA<FormatException>()));
    });
  });
}
