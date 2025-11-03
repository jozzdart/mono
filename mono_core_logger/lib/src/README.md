# mono_core_logger/src

This package provides pure abstractions for robust CLI logging. It contains
contracts only: no terminal control, no ANSI, no IO side effects. Concrete
implementations can target different environments (TTY, non-TTY, file, JSON).

- Import types via:

```dart
import 'package:mono_core_logger/mono_core_logger.dart';
```

## Folder map

- core: foundational types (levels, records, messages, errors, redaction, events, time, ids)
- logging: logger API and pipeline (sinks, router, filters, scopes)
- progress: progress contracts and grouping/throttling hints
- prompts: interactive prompt models, sessions, key mapping (no IO)
- renderables: structured content for rich output (lists, tables, code, diff, tree)
- ui: layout and style tokens (hints for renderers)

## Design principles

- Structured, immutable data: `LogRecord` and related types are immutable.
- Implementation-agnostic: no dependencies on terminal control.
- Separation of concerns: models vs renderers, records vs formatting vs routing.
- Extensibility: pluggable sinks/formatters/routers; renderable content is open-ended.

## Out of scope

- ANSI styling, cursor control, TTY detection, filesystem/network IO.
- Default implementations (to be provided by a separate package).

## Example (conceptual)

```dart
import 'package:mono_core_logger/mono_core_logger.dart';

void run(Logger logger) {
  final scope = logger.scoped(
    capture: CaptureMode.bufferFiltered,
    silence: SilencePolicy.importantOnly,
  );

  final task = logger.startTask('Build', initialFraction: 0.0);
  task.update(fraction: 0.5, message: 'Halfway');
  task.log('Compiling 42 files');
  task.finish(success: true, message: 'Done');

  final summary = scope.flush();
  scope.close();
}
```
