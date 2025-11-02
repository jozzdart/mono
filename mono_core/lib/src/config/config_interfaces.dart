import 'package:mono_core/mono_core.dart';

abstract class ConfigLoader {
  const ConfigLoader();
  MonoConfig load(String text);
}

@immutable
abstract class ConfigValidator {
  const ConfigValidator();
  List<ConfigIssue> validate(MonoConfig config);
}

@immutable
abstract class SchemaProvider {
  const SchemaProvider();
  Map<String, Object?> jsonSchema();
}
