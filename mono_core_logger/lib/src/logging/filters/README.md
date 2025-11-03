# logging/filters/

Declarative filtering contracts.

## Expression AST

- `LevelAtLeast(level)`: allow records with level priority >= given level.
- `HasTag(tag)`: match records containing a tag.
- `CategoryIs(category)`: match category name.
- `And([...])`, `Or([...])`, `Not(expr)`: boolean composition.

## Compiler

`FilterCompiler` turns an expression into a `LogFilter` (predicate) used by
routers/scopes/sinks.

### Example (conceptual)

```dart
import 'package:mono_core_logger/mono_core_logger.dart';

LogFilter buildFilter(FilterCompiler compiler) {
  final expr = And([
    LevelAtLeast(LogLevel.info),
    Not(HasTag('debug-only')),
  ]);
  return compiler.compile(expr);
}
```

## Guidance

- Keep compilation cheap; evaluate only necessary fields of `LogRecord`.
- Prefer composing small expressions for better reuse/testability.
