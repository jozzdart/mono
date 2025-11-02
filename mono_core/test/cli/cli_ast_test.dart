import 'package:mono_core/mono_core.dart';
import 'package:test/test.dart';

void main() {
  group('CliCommandTree', () {
    test('stores root command', () {
      final root = CliCommand(name: 'root');
      final tree = CliCommandTree(root: root);
      expect(tree.root, same(root));
    });
  });

  group('CliCommand', () {
    test('defaults: description=null, lists empty and unmodifiable', () {
      final cmd = CliCommand(name: 'build');
      expect(cmd.name, 'build');
      expect(cmd.description, isNull);
      expect(cmd.options, isEmpty);
      expect(cmd.arguments, isEmpty);
      expect(cmd.subcommands, isEmpty);

      expect(() => cmd.options.add(const CliOption(name: 'v')),
          throwsA(isA<UnsupportedError>()));
      expect(() => cmd.arguments.add(const CliArgument(name: 'x')),
          throwsA(isA<UnsupportedError>()));
      expect(() => cmd.subcommands.add(CliCommand(name: 'child')),
          throwsA(isA<UnsupportedError>()));
    });

    test('stores provided options/args/subcommands', () {
      final opt = CliOption(name: 'verbose', short: 'v', help: 'be verbose');
      const arg =
          CliArgument(name: 'path', help: 'project path', optional: false);
      final child = CliCommand(name: 'test');
      final cmd = CliCommand(
        name: 'run',
        description: 'Run tasks',
        options: [opt],
        arguments: const [arg],
        subcommands: [child],
      );

      expect(cmd.description, 'Run tasks');
      expect(cmd.options, hasLength(1));
      expect(cmd.options.first, same(opt));
      expect(cmd.arguments, hasLength(1));
      expect(cmd.arguments.first, arg);
      expect(cmd.subcommands, hasLength(1));
      expect(cmd.subcommands.first, same(child));
    });
  });

  group('CliOption', () {
    test('defaults: takesValue=true, multiple=false', () {
      final o = CliOption(name: 'config');
      expect(o.name, 'config');
      expect(o.short, isNull);
      expect(o.help, isNull);
      expect(o.takesValue, isTrue);
      expect(o.multiple, isFalse);
    });

    test('stores provided fields', () {
      final o = CliOption(
        name: 'tag',
        short: 't',
        help: 'Filter by tag',
        takesValue: true,
        multiple: true,
      );
      expect(o.short, 't');
      expect(o.help, 'Filter by tag');
      expect(o.multiple, isTrue);
    });
  });

  group('CliArgument', () {
    test('defaults: optional=true, multiple=false', () {
      const a = CliArgument(name: 'target');
      expect(a.name, 'target');
      expect(a.help, isNull);
      expect(a.optional, isTrue);
      expect(a.multiple, isFalse);
    });

    test('stores provided fields', () {
      const a = CliArgument(
          name: 'files',
          help: 'files to include',
          optional: false,
          multiple: true);
      expect(a.help, 'files to include');
      expect(a.optional, isFalse);
      expect(a.multiple, isTrue);
    });
  });

  group('CliInvocation', () {
    test('defaults empty, unmodifiable collections', () {
      const inv = CliInvocation(commandPath: []);
      expect(inv.commandPath, isEmpty);
      expect(inv.options, isEmpty);
      expect(inv.positionals, isEmpty);
      expect(inv.targets, isEmpty);

      expect(() => inv.commandPath.add('x'), throwsA(isA<UnsupportedError>()));
      expect(() => inv.positionals.add('x'), throwsA(isA<UnsupportedError>()));
      expect(() => inv.targets.add(const TargetAll()),
          throwsA(isA<UnsupportedError>()));
      expect(() => inv.options['k'] = const ['v'],
          throwsA(isA<UnsupportedError>()));
      expect(() => inv.options.clear(), throwsA(isA<UnsupportedError>()));
    });

    test('stores provided fields as-is', () {
      final path = <String>['mono', 'run'];
      final opts = <String, List<String>>{
        'tag': ['x', 'y']
      };
      final pos = <String>['rest'];
      const t = <TargetExpr>[TargetPackage('core')];

      final inv = CliInvocation(
          commandPath: path, options: opts, positionals: pos, targets: t);
      expect(inv.commandPath, same(path));
      expect(inv.options, same(opts));
      expect(inv.positionals, same(pos));
      expect(inv.targets, t);
    });
  });

  group('Command tree structure', () {
    test('nested subcommands retained', () {
      final leaf = CliCommand(name: 'leaf');
      final mid = CliCommand(name: 'mid', subcommands: [leaf]);
      final root = CliCommand(name: 'root', subcommands: [mid]);
      final tree = CliCommandTree(root: root);

      expect(tree.root.subcommands.single.name, 'mid');
      expect(tree.root.subcommands.single.subcommands.single.name, 'leaf');
    });
  });
}
