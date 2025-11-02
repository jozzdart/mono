import 'package:meta/meta.dart';
import 'config_types.dart';

@immutable
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

