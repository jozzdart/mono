# mono_core_logger

Pure abstractions for robust CLI logging: levels, structured records, filters/silencing,
progress with overlay or pinned display hints, prompts, styling tokens, and renderables.

No concrete IO or terminal control — implementations live in a separate package (e.g. `mono_logger`).

## Features (contracts)

- Structured logs (`LogRecord`) with levels, tags, fields, categories, and context
- Filters, silencing scopes, capture/buffering and summaries (`LogScope`)
- Progress tasks with fraction and task-scoped logs (`ProgressHandle`)
- Prompts via `PromptDriver` (confirm/select/input)
- Styling via semantic tokens (`StyleToken`, `StyleTheme`)
- Renderables for lists/tables/sections
- Sinks, formatters, and router as pluggable interfaces

## Example (intended usage)

```dart
final logger = /* provided by implementation */;

final scope = logger.scoped(
  capture: CaptureMode.bufferFiltered,
  silence: SilencePolicy.importantOnly,
);

final task = logger.startTask('Scanning workspace', initialFraction: 0.0);
// ... work ...
task.update(fraction: 0.5, message: 'Halfway');
task.log('Found 12 projects');
// ... work ...
task.finish(success: true, message: 'Done');

final summary = scope.flush();
scope.close();
```

## Notes

- All APIs are pure contracts; no side-effects beyond the interfaces.
- Concrete implementations decide formatting, ANSI, and terminal behavior.
