import 'package:meta/meta.dart';

@immutable
class MonoConfig {
  const MonoConfig({
    required this.include,
    required this.exclude,
    this.packages = const {},
    this.groups = const {},
    this.tasks = const {},
    this.settings = const Settings(),
  });

  final List<String> include;
  final List<String> exclude;
  // name -> relative path overrides
  final Map<String, String> packages;
  // group -> list of members (names or globs)
  final Map<String, List<String>> groups;
  // taskId -> definition
  final Map<String, TaskDefinition> tasks;
  final Settings settings;
}

@immutable
class TaskDefinition {
  const TaskDefinition({
    this.plugin,
    this.dependsOn = const <String>[],
    this.env = const <String, String>{},
    this.run = const <String>[],
  });
  final String? plugin;
  final List<String> dependsOn;
  final Map<String, String> env;
  // For exec-like tasks; interpreted by plugins
  final List<String> run;
}

@immutable
class Settings {
  const Settings({
    this.concurrency = 'auto',
    this.defaultOrder = 'dependency',
    this.shellWindows = 'powershell',
    this.shellPosix = 'bash',
  });
  final String concurrency; // number or 'auto'
  final String defaultOrder; // 'dependency' or 'none'
  final String shellWindows;
  final String shellPosix;
}

@immutable
class ConfigIssue {
  const ConfigIssue(this.message,
      {this.severity = IssueSeverity.error, this.path});
  final String message;
  final IssueSeverity severity;
  final String? path; // JSON pointer-like path
}

enum IssueSeverity { info, warning, error }
