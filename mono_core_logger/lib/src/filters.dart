import 'package:mono_core_logger/mono_core_logger.dart';

typedef LogFilter = bool Function(LogRecord record);

enum FilterDecision { allow, deny }

class FilterRule {
  final LogFilter test;
  final FilterDecision decision;
  const FilterRule(this.test, this.decision);
}

/// Policy interface that can combine multiple rules.
abstract class FilterPolicy {
  FilterDecision decide(LogRecord record);
}
