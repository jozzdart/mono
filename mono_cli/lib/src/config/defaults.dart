import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

class ConfigNormalizationResult {
  ConfigNormalizationResult({required this.yaml, required this.messages});
  final String yaml;
  final List<String> messages;
}

MonoConfig defaultConfig() {
  return MonoConfig(
    include: ["**"],
    exclude: [
      "monocfg/**",
      ".dart_tool/**",
    ],
    dartProjects: {},
    flutterProjects: {},
    groups: {},
    tasks: {},
    settings: Settings(
      concurrency: Concurrency.auto.toString(),
      defaultOrder: orderToString(DefaultOrder.dependency),
      shellWindows: 'powershell',
      shellPosix: 'bash',
    ),
    logger: buildLoggerSettings(),
  );
}

String _quote(String v) {
  if (v.contains('#') ||
      v.contains(':') ||
      v.contains('*') ||
      v.contains(' ')) {
    return '"${v.replaceAll('"', '\\"')}"';
  }
  return v;
}

String toYaml(
  MonoConfig cfg, {
  required String monocfgPath,
}) {
  final sb = StringBuffer();
  sb.writeln('# mono configuration');
  sb.writeln('# Settings: basic CLI options');
  sb.writeln('settings:');
  sb.writeln('  monocfgPath: $monocfgPath');
  sb.writeln('  concurrency: ${cfg.settings.concurrency}');
  sb.writeln('  defaultOrder: ${cfg.settings.defaultOrder}');
  sb.writeln('');
  sb.writeln('# Logger: colors/icons/timestamp');
  sb.writeln('logger:');
  sb.writeln('  color: ${cfg.logger.color}');
  sb.writeln('  icons: ${cfg.logger.icons}');
  sb.writeln('  timestamp: ${cfg.logger.timestamp}');
  sb.writeln('');
  sb.writeln('# Include globs used to scan for packages');
  sb.writeln('# Example:');
  sb.writeln('# - packages/**');
  sb.writeln('# - apps/**');
  sb.writeln('include:');
  for (final g in cfg.include) {
    sb.writeln('  - ${_quote(g)}');
  }
  sb.writeln('');
  sb.writeln('# Exclude globs to skip during scan');
  sb.writeln('# Example:');
  sb.writeln('# - **/build/**');
  sb.writeln('# - **/.dart_tool/**');
  sb.writeln('exclude:');
  for (final g in cfg.exclude) {
    sb.writeln('  - ${_quote(g)}');
  }
  sb.writeln('');
  sb.writeln('# Dart projects map (name -> relative path)');
  sb.writeln('# Example:');
  sb.writeln('# core: packages/core');
  sb.writeln('dart_projects:');
  if (cfg.dartProjects.isNotEmpty) {
    for (final e in cfg.dartProjects.entries) {
      sb.writeln('  ${e.key}: ${_quote(e.value)}');
    }
  }
  sb.writeln('');
  sb.writeln('# Flutter projects map (name -> relative path)');
  sb.writeln('# Example:');
  sb.writeln('# app: apps/app');
  sb.writeln('flutter_projects:');
  if (cfg.flutterProjects.isNotEmpty) {
    for (final e in cfg.flutterProjects.entries) {
      sb.writeln('  ${e.key}: ${_quote(e.value)}');
    }
  }
  sb.writeln('');
  sb.writeln('# Groups combine packages and/or other groups');
  sb.writeln('# Example:');
  sb.writeln('# apps:');
  sb.writeln('#   - app');
  sb.writeln('# tooling:');
  sb.writeln('#   - core');
  sb.writeln('groups:');
  if (cfg.groups.isNotEmpty) {
    for (final e in cfg.groups.entries) {
      sb.writeln('  ${e.key}:');
      for (final item in e.value) {
        sb.writeln('    - ${_quote(item)}');
      }
    }
  }
  sb.writeln('');
  sb.writeln(
      '# Tasks can be invoked as commands (merged with monocfg/tasks.yaml)');
  sb.writeln('# Example:');
  sb.writeln('# build_all:');
  sb.writeln('#   plugin: exec');
  sb.writeln('#   run:');
  sb.writeln('#     - dart run build_runner build -d');
  sb.writeln('tasks:');
  if (cfg.tasks.isNotEmpty) {
    for (final e in cfg.tasks.entries) {
      sb.writeln('  ${e.key}:');
      final def = e.value;
      if (def.plugin != null) sb.writeln('    plugin: ${def.plugin}');
      if (def.dependsOn.isNotEmpty) {
        sb.writeln('    dependsOn:');
        for (final d in def.dependsOn) {
          sb.writeln('      - ${_quote(d)}');
        }
      }
      if (def.env.isNotEmpty) {
        sb.writeln('    env:');
        for (final ev in def.env.entries) {
          sb.writeln('      ${ev.key}: ${_quote(ev.value)}');
        }
      }
      if (def.run.isNotEmpty) {
        sb.writeln('    run:');
        for (final r in def.run) {
          sb.writeln('      - ${_quote(r)}');
        }
      }
    }
  }
  return sb.toString();
}

ConfigNormalizationResult normalizeRootConfig(
  String rawYaml, {
  required String monocfgPath,
  Logger? logger,
}) {
  final defaults = defaultConfig();
  final loader = const YamlConfigLoader();
  final loaded = loader.load(rawYaml);
  final msgs = <String>[];

  // Validate and coerce settings
  String concurrency = loaded.settings.concurrency;
  final conc = int.tryParse(concurrency);
  if (!(concurrency == Concurrency.auto.toString() ||
      (conc != null && conc > 0))) {
    msgs.add(
        "settings.concurrency had invalid value '$concurrency'; reset to '${Concurrency.auto}'");
    concurrency = Concurrency.auto.toString();
  }
  String order = loaded.settings.defaultOrder;
  if (order != orderToString(DefaultOrder.dependency) &&
      order != orderToString(DefaultOrder.none)) {
    msgs.add(
        "settings.defaultOrder had invalid value '$order'; reset to '${orderToString(DefaultOrder.dependency)}'");
    order = defaults.settings.defaultOrder;
  }

  // Logger booleans
  bool color = loaded.logger.color;
  bool icons = loaded.logger.icons;
  bool timestamp = loaded.logger.timestamp;
  // (loader already coerces best-effort; defaults applied below if missing)

  // Build normalized config using known keys only
  final normalized = MonoConfig(
    include: loaded.include.isEmpty ? defaults.include : loaded.include,
    exclude: loaded.exclude.isEmpty ? defaults.exclude : loaded.exclude,
    dartProjects: loaded.dartProjects,
    flutterProjects: loaded.flutterProjects,
    groups: loaded.groups,
    tasks: loaded.tasks,
    settings: Settings(
      concurrency: concurrency,
      defaultOrder: order,
      shellWindows: loaded.settings.shellWindows.isEmpty
          ? defaults.settings.shellWindows
          : loaded.settings.shellWindows,
      shellPosix: loaded.settings.shellPosix.isEmpty
          ? defaults.settings.shellPosix
          : loaded.settings.shellPosix,
    ),
    logger: LoggerSettings(
      color: color,
      icons: icons,
      timestamp: timestamp,
    ),
  );

  // Missing defaults logging (simple checks)
  if (rawYaml.trim().isEmpty) {
    msgs.add('Created default mono.yaml');
  } else {
    if (!rawYaml.contains(SectionKeys.logger)) {
      msgs.add('logger section was missing; added defaults');
    }
    if (!rawYaml.contains(SectionKeys.settings)) {
      msgs.add('settings section was missing; added defaults');
    }
  }

  for (final m in msgs) {
    logger?.log(m, level: 'info');
  }

  final yaml = toYaml(
    normalized,
    monocfgPath: monocfgPath,
  );
  return ConfigNormalizationResult(yaml: yaml, messages: msgs);
}
