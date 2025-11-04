import 'package:mono_cli/mono_cli.dart';
import 'package:mono_core/mono_core.dart';

@immutable
class YamlConfigLoader implements ConfigLoader {
  const YamlConfigLoader();

  @override
  MonoConfig load(String text) {
    final raw = loadYaml(text, recover: true);
    final m = (raw is YamlMap) ? raw : const {};

    List<String> strList(Object? v) => v is YamlList
        ? v.nodes.map((e) => e.value.toString()).toList()
        : (v is List)
            ? v.map((e) => '$e').toList()
            : <String>[];

    Map<String, String> mapSS(Object? v) {
      if (v is YamlMap) {
        return {
          for (final e in v.nodes.entries)
            e.key.value.toString(): e.value.value.toString(),
        };
      }
      if (v is Map) {
        return {for (final e in v.entries) '${e.key}': '${e.value}'};
      }
      return const {};
    }

    Map<String, List<String>> mapSL(Object? v) {
      if (v is YamlMap) {
        return {
          for (final e in v.nodes.entries)
            e.key.value.toString(): strList(e.value.value),
        };
      }
      if (v is Map) {
        return {
          for (final e in v.entries)
            '${e.key}': (e.value is List)
                ? (e.value as List).map((x) => '$x').toList()
                : <String>[],
        };
      }
      return const {};
    }

    Map<String, TaskDefinition> tasks(Object? v) {
      final out = <String, TaskDefinition>{};
      final base = (v is YamlMap) ? v : (v is Map ? v : const {});
      for (final entry in base.entries) {
        final key = '${entry.key}';
        final tv = entry.value;
        String? plugin;
        List<String> dependsOn = const [];
        Map<String, String> env = const {};
        List<String> run = const [];
        if (tv is Map || tv is YamlMap) {
          final mm = tv is YamlMap ? tv : (tv as Map);
          plugin = mm['plugin']?.toString();
          dependsOn = strList(mm['dependsOn']);
          env = mapSS(mm['env']);
          run = strList(mm['run']);
        }
        out[key] = TaskDefinition(
          plugin: plugin,
          dependsOn: dependsOn,
          env: env,
          run: run,
        );
      }
      return out;
    }

    final include = strList(m['include']);
    final exclude = strList(m['exclude']);
    final packages = mapSS(m['packages']);
    final groups = mapSL(m['groups']);
    final taskDefs = tasks(m['tasks']);

    final settingsNode = m[SectionKeys.settings];
    final settings = settingsNode is Map || settingsNode is YamlMap
        ? Settings(
            concurrency: (settingsNode[OptionKeys.concurrency] ??
                    Concurrency.auto.toString())
                .toString(),
            defaultOrder: (settingsNode['defaultOrder'] ??
                    orderToString(DefaultOrder.dependency))
                .toString(),
            shellWindows:
                (settingsNode['shellWindows'] ?? 'powershell').toString(),
            shellPosix: (settingsNode['shellPosix'] ?? 'bash').toString(),
          )
        : const Settings();

    final loggerNode = m[SectionKeys.logger];
    bool asBool(Object? v, bool d) {
      if (v is bool) return v;
      if (v is String) {
        final s = v.toLowerCase().trim();
        if (s == 'true' || s == '1' || s == 'yes') return true;
        if (s == 'false' || s == '0' || s == 'no') return false;
      }
      return d;
    }

    final logger = loggerNode is Map || loggerNode is YamlMap
        ? LoggerSettings(
            color: asBool(loggerNode[OptionKeys.color], true),
            icons: asBool(loggerNode[OptionKeys.icons], true),
            timestamp: asBool(loggerNode[OptionKeys.timestamp], false),
          )
        : const LoggerSettings();

    return MonoConfig(
      include: include,
      exclude: exclude,
      packages: packages,
      groups: groups,
      tasks: taskDefs,
      settings: settings,
      logger: logger,
    );
  }
}
