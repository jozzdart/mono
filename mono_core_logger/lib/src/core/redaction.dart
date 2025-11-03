typedef Redactor = Object? Function(String key, Object? value);

abstract class RedactionPolicy {
  Object? redact(String key, Object? value);
  bool isSensitive(String key);
}

class SensitiveField {
  final String key;
  const SensitiveField(this.key);
}
