import 'package:mono_core/mono_core.dart';

@immutable
class YamlConfigValidator implements ConfigValidator {
  const YamlConfigValidator();

  @override
  List<ConfigIssue> validate(MonoConfig config) {
    final issues = <ConfigIssue>[];
    // Basic checks; expand later with full schema validation if needed.
    if (config.include.isEmpty && config.packages.isEmpty) {
      issues.add(const ConfigIssue(
        'Either include globs or packages overrides should be provided',
        severity: IssueSeverity.warning,
        path: '/include',
      ));
    }
    return issues;
  }
}
