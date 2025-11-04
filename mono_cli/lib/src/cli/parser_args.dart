import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

@immutable
class ArgsTokenizer implements CliTokenizer {
  const ArgsTokenizer();

  @override
  List<String> tokenize(String input) {
    // Very naive split (space). Proper quoting/escape handling can be added later if needed.
    return input.trim().isEmpty ? const [] : input.trim().split(RegExp(r'\s+'));
  }
}

@immutable
class ArgsCliParser implements CliParser {
  const ArgsCliParser();

  @override
  CliInvocation parse(List<String> argv, {CliCommandTree? commandTree}) {
    if (argv.isEmpty) {
      return const CliInvocation(commandPath: ['help']);
    }

    final command = argv.first;
    final rest = argv.sublist(1);

    final parser = ArgParser(allowTrailingOptions: true)
      ..addOption(OptionKeys.concurrency, abbr: 'j')
      ..addOption(OptionKeys.order)
      ..addFlag(OptionKeys.dryRun, defaultsTo: false)
      ..addFlag(OptionKeys.check, defaultsTo: false)
      ..addMultiOption(OptionKeys.targets, abbr: 't')
      // Global pretty-logging flags (only included in options when explicitly passed)
      ..addFlag(OptionKeys.color, defaultsTo: true, negatable: true)
      ..addFlag(OptionKeys.icons, defaultsTo: true, negatable: true)
      ..addFlag(OptionKeys.timestamp, defaultsTo: false, negatable: true);

    final results = parser.parse(rest);

    final positionals = results.rest;
    final options = <String, List<String>>{};
    void put(String k, Object? v) {
      if (v == null) return;
      final list = <String>[];
      if (v is List) {
        list.addAll(v.map((e) => '$e'));
      } else {
        list.add('$v');
      }
      if (list.isEmpty) return;
      options[k] = list;
    }

    put(OptionKeys.concurrency, results[OptionKeys.concurrency]);
    put(OptionKeys.order, results[OptionKeys.order]);
    if (results[OptionKeys.dryRun] == true) put(OptionKeys.dryRun, 'true');
    if (results[OptionKeys.check] == true) put(OptionKeys.check, 'true');
    put(OptionKeys.targets, results[OptionKeys.targets]);

    // Only include pretty-logging flags when explicitly provided on CLI
    if (results.wasParsed(OptionKeys.color)) {
      put(OptionKeys.color,
          results[OptionKeys.color] == true ? 'true' : 'false');
    }
    if (results.wasParsed(OptionKeys.icons)) {
      put(OptionKeys.icons,
          results[OptionKeys.icons] == true ? 'true' : 'false');
    }
    if (results.wasParsed(OptionKeys.timestamp)) {
      put(OptionKeys.timestamp,
          results[OptionKeys.timestamp] == true ? 'true' : 'false');
    }

    final targets = <TargetExpr>[];
    for (final token in positionals.expand((p) => p.split(','))) {
      final t = token.trim();
      if (t.isEmpty) continue;
      if (t == 'all') {
        targets.add(const TargetAll());
      } else if (t.startsWith(':')) {
        targets.add(TargetGroup(t.substring(1)));
      } else if (t.contains('*') || t.contains('?')) {
        targets.add(TargetGlob(t));
      } else {
        targets.add(TargetPackage(t));
      }
    }

    return CliInvocation(
      commandPath: [command],
      options: options,
      positionals: positionals,
      targets: targets,
    );
  }
}
