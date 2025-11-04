import 'package:mono_core/mono_core.dart';

class SectionKeys {
  static const String settings = 'settings';
  static const String logger = 'logger';
  static const String include = 'include';
  static const String exclude = 'exclude';
  static const String packages = 'packages';
  static const String groups = 'groups';
  static const String tasks = 'tasks';
}

class OptionKeys {
  static const String concurrency = 'concurrency';
  static const String order = 'order';
  static const String targets = 'targets';
  static const String dryRun = 'dry-run';
  static const String check = 'check';
  static const String color = 'color';
  static const String icons = 'icons';
  static const String timestamp = 'timestamp';
}

enum DefaultOrder { dependency, none }

String orderToString(DefaultOrder order) =>
    order == DefaultOrder.dependency ? 'dependency' : 'none';

DefaultOrder parseOrder(String? value) {
  switch (value) {
    case 'none':
      return DefaultOrder.none;
    case 'dependency':
    default:
      return DefaultOrder.dependency;
  }
}

class Concurrency {
  const Concurrency._(this.value);
  final int? value; // null => auto
  bool get isAuto => value == null;
  static const Concurrency auto = Concurrency._(null);
  static Concurrency of(int v) => Concurrency._(v <= 0 ? null : v);
  @override
  String toString() => isAuto ? 'auto' : '$value';
  static Concurrency parse(String? s) {
    if (s == null) return Concurrency.auto;
    final n = int.tryParse(s);
    if (n != null && n > 0) return Concurrency.of(n);
    if (s.trim().toLowerCase() == 'auto') return Concurrency.auto;
    return Concurrency.auto;
  }
}

LoggerSettings buildLoggerSettings(
    {bool? color, bool? icons, bool? timestamp}) {
  return LoggerSettings(
    color: color ?? true,
    icons: icons ?? true,
    timestamp: timestamp ?? false,
  );
}
