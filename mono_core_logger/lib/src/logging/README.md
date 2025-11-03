# logging/

Contracts for the logging pipeline and API.

## Components

- `Logger` and `LoggerFactory`: high-level API and child logger creation.
- `LogSink`: side-effect target (e.g., console, file). No IO here, just the contract. Implements `flush()`/`close()` for buffered/async outputs.
- `LogFormatter`: converts a `LogRecord` into an output object (string, renderable, etc.).
- `LogRouter`: routes records to sinks (optionally with per-sink filters). Exposes `flush()`/`close()` to cascade lifecycle to sinks.
- `LogPipeline`: convenience composition of `LogFormatter` + `LogRouter`.
- `FilterPolicy`, `LogFilter`: filtering hooks.
- `LogScope`: capture/silence policies with summary reporting.

## Flow

1. App calls `Logger.log(...)` or helpers like `info/warn/error`.
2. The pipeline may apply filters (global, per-scope, per-sink).
3. Formatter transforms the record into output form.
4. Router sends the record to one or more sinks.
5. Sinks perform side-effects (outside this package).
6. `flush()`/`close()` drain and finalize outputs when the app exits or before critical transitions.

## Scopes

- `CaptureMode`: buffer all/filtered/summary-only or bypass.
- `SilencePolicy`: hide non-critical logs while work is noisy.
- `SummaryReport`: counts and collected warnings/errors for end-of-scope display.

## Example (conceptual)

```dart
import 'package:mono_core_logger/mono_core_logger.dart';

void example(Logger logger) {
  final scope = logger.scoped(
    capture: CaptureMode.bufferFiltered,
    silence: SilencePolicy.importantOnly,
  );
  logger.info('Start');
  logger.warn('Heads up');
  logger.error('Something failed');
  final summary = scope.flush();
  scope.close();
}
```

## Notes for implementations

- Ensure thread-safety if logs can be emitted from multiple isolates.
- Avoid expensive formatting when filtered out (lazy if possible in impl).
- Per-sink filters allow routing verbose output separately from summaries.
