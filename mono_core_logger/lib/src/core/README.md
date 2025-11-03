# core/

Foundational types used across the logger abstractions. These have no side
effects and are designed to be immutable and composable.

## Types

- `LogLevel` and `LogCategory`: semantic severity and optional category hints.
- `LogRecord`: immutable structured record with timestamp, level, body, tags,
  category, `fields`, and `context`.
- `LogContext`: correlation/task/scope identifiers plus arbitrary `extra` map.
- `MessageBody`: union for text vs `Renderable` content (`TextMessage`,
  `RenderableMessage`).
- `ExceptionInfo`, `StackFrame`, `ErrorRecord`: standardized error reporting.
- `RedactionPolicy`, `SensitiveField`, `Redactor`: structured data redaction.
- `LoggerEvent`: typed events for logs and progress updates.
- `Clock`: time source abstraction for testability.
- `TaskId`, `ScopeId`: typed aliases for ids.

## Invariants

- `LogRecord` and subtypes are immutable.
- `fields` must be serializable data and safe to pass through a redaction layer.
- `timestamp` should reflect the creation time of the record by the producer.
- `context` can be merged across scopes using `LogContext.merged`.

## Usage

```dart
import 'package:mono_core_logger/mono_core_logger.dart';

final record = LogRecord(
  timestamp: DateTime.now(),
  level: LogLevel.info,
  body: 'Scanning...',
  tags: const ['scanner'],
  category: 'scan',
  fields: const {'projects': 12},
);
```

## Extension guidance

- Prefer adding new semantic fields into `fields` to avoid breaking changes.
- New levels/categories should remain implementation-agnostic.
- Keep new types immutable and serializable; avoid lazy IO or closures.
