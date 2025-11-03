import 'package:mono_core_logger/mono_core_logger.dart';

abstract class FilterExpression {
  const FilterExpression();
}

class LevelAtLeast implements FilterExpression {
  final LogLevel level;
  const LevelAtLeast(this.level);
}

class HasTag implements FilterExpression {
  final LogTag tag;
  const HasTag(this.tag);
}

class CategoryIs implements FilterExpression {
  final LogCategory category;
  const CategoryIs(this.category);
}

class And implements FilterExpression {
  final List<FilterExpression> nodes;
  const And(this.nodes);
}

class Or implements FilterExpression {
  final List<FilterExpression> nodes;
  const Or(this.nodes);
}

class Not implements FilterExpression {
  final FilterExpression node;
  const Not(this.node);
}

/// Compiles an expression into a predicate for routing/scope evaluation.
abstract class FilterCompiler {
  LogFilter compile(FilterExpression expr);
}
