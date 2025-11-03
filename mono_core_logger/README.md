# mono_core_logger

Pure abstractions for robust CLI logging: levels, structured records, filters/silencing,
progress with overlay or pinned display hints, prompts, styling tokens, and renderables.

No concrete IO or terminal control — implementations live in a separate package (e.g. `mono_logger`).

## What implementers should build

This package defines contracts only. Implementers provide concrete behavior by wiring:

- A `Logger` implementation (public API surface)
- A logging pipeline: `LogFormatter` → `LogRouter` → one or more `LogSink`s
- Scope handling with capture/silencing and `SummaryReport`
- Progress rendering honoring `ProgressDisplayMode` and task-scoped logs
- Prompt runtime that uses `PromptDriver` and the prompt models (no IO here)
- A `StyleTheme` and mapping of `StyleToken`s to actual colors/attributes
- A renderer for `Renderable` content and layout hints (`RegionId`, pinned/overlay)

> All IO/terminal control (ANSI, cursor moves, width detection, etc.) belongs in your implementation package, not here.

## Feature map (contracts)

- Structured logs: `LogRecord`, `LogLevel`, tags, categories, `LogFields`, `LogContext`
- Filters: predicates (`LogFilter`), policies, and expression AST + `FilterCompiler`
- Scopes: `LogScope` with `CaptureMode` and `SilencePolicy`, `SummaryReport`
- Progress: `ProgressHandle`, `ProgressTask`, `ProgressDisplayMode`, groups, throttling
- Prompts: `PromptDriver`, `PromptModel`, `PromptSession`, key mapping, renderer separation
- UI hints: `StyleToken`/`StyleTheme`, `RegionId`, pinned/overlay hints
- Renderables: lists, tables, sections, key-values, code blocks, diffs, trees
- Redaction: `RedactionPolicy`/`Redactor` for sensitive fields
- Utilities: `Clock`, ids (`TaskId`, `ScopeId`), cancel token

See folder documentation in `lib/src/*/README.md` for deep dives.

## Implementation guide

### 1) Logger API

Provide a `Logger` that:

- Accepts `Object` messages which may be `String` or any `Renderable`
- Exposes convenience methods: `trace/debug/info/success/warn/error/fatal`
- Supports `tags`, `category`, `fields` and `context` for structured routing
- Emits via your pipeline (formatter → router → sinks)

Recommended:

- Merge a default `LogContext` and allow child loggers via `LoggerFactory`
- Apply `RedactionPolicy` before formatting

### 2) Pipeline: formatter, router, sinks

- `LogFormatter`: map `LogRecord` → concrete output (e.g., colorized string, JSON)
- `LogRouter`: route records to sinks, optionally with per-sink `LogFilter`
- `LogSink`: perform side effects (console, file, memory); expose `flush()` if useful

Tips:

- Avoid expensive formatting for records that will be filtered out
- Support multiple sinks with different filtering (e.g., verbose console vs. JSON file)

### 3) Scopes: silencing, capture, summaries

- `CaptureMode`:
  - `none`: pass-through
  - `bufferAll`: buffer all records for the scope
  - `bufferFiltered`: buffer only records matching scope filter
  - `summaryOnly`: keep counts; optionally store warnings/errors for report
- `SilencePolicy`:
  - `none`: do not suppress
  - `importantOnly`: hide info/debug/trace
  - `errorsOnly`: show only errors
  - `all`: suppress all

Behavior for long-running processes:

- Quiet during execution; print collected summary at the end
- Show running progress in a pinned region; append filtered messages below it as they arrive
- Overlay live progress where only the progress line updates; logs print normally above/below

### 4) Progress: percent, live logs, groups

- `startTask(label, initialFraction, display)` returns a `ProgressHandle`
- `update(fraction, message)` updates progress (fraction 0..1; `null` indeterminate)
- `log(message, level)` emits task-scoped logs which your renderer can keep beneath the task
- `finish(success, message)` concludes the task and frees any region
- Groups: `ProgressGroupHandle` can nest tasks and aggregate state
- Throttling: use `UpdateRateController` to avoid flicker on frequent updates

### 5) Prompts: confirm/select/input and checkbox multi-select

- Use `PromptDriver` to offer:
  - confirm (yes/no)
  - select (single choice)
  - input (text, optionally secret)
- For checkbox-style multi-select, use `MultiSelectPromptModel<T>` with `SelectionConstraints`
- Separate prompt model/state (`PromptModel`/`PromptSession`) from rendering (`PromptRenderer`)
- Key handling: map device keys to logical `PromptInput` via a `PromptKeyMap`
- Accessibility: provide clear submit/cancel and predictable focus movement

### 6) UI hints and styling

- Map `StyleToken`s to your color/attribute system
- Respect layout hints:
  - `overlay`: single updating line/region
  - `pinnedBelow`/`pinnedAbove`: reserved region that updates while logs continue elsewhere
- Degrade gracefully in non-TTY environments (no cursor control; print simple lines)

### 7) Renderables

- List/table/section/key-values/code/diff/tree are data models; your renderer formats them
- Support nested renderables; truncate or paginate large content where appropriate

### 8) Filtering + expressions

- Implement a `FilterCompiler` from the expression AST to a `LogFilter`
- Common patterns: `LevelAtLeast`, `HasTag`, `CategoryIs`, boolean composition
- Apply filters at scope level and per-sink in the router

### 9) Redaction

- Apply `RedactionPolicy` to `fields` (and any string bodies if needed)
- Typical approach: redact keys like `token`, `password`, `secret` before formatting

### 10) Performance & correctness

- Minimize allocations in hot paths; throttle progress updates
- Be thread/isolates safe if used concurrently
- Avoid interleaving progress display with normal logs unless using pinned regions

## Example (intended usage)

```dart
final logger = /* provided by implementation */;

final scope = logger.scoped(
  capture: CaptureMode.bufferFiltered,
  silence: SilencePolicy.importantOnly,
);

final task = logger.startTask('Scanning workspace', initialFraction: 0.0,
    display: ProgressDisplayMode.pinnedBelow);
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
- Avoid `dynamic`; use `Object?` and generics for typed contracts.
