## 0.0.6

- Removed export of `mono_core`
- `DefaultCommandEnvironmentBuilder` now uses injected core dependencies
- New: `DefaultCliEngine` implements core `CliEngine`
- `DefaultCliEngine` now uses injected router factory instead of creating router directly

## 0.0.5

- Breaking: Moved CLI IO to `Logger` across router and executor implementations.
  - `DefaultCommandRouter.tryDispatch` now accepts `{ required CliInvocation inv, required Logger logger }`.
  - `DefaultTaskExecutor.execute` now takes a `Logger` and logs messages instead of writing to `IOSink`.
  - Updated tests to use an in-memory `Logger` buffer.

## 0.0.4

- Implemented `DefaultCommandEnvironmentBuilder` that assembles the command environment from disk and invocation options.
  - Loads `mono.yaml`, extracts `monocfgPath`.
  - Scans packages, builds dependency graph, loads file-based groups.
  - Computes effective order and concurrency; provides a `TargetSelector`.
- Implemented `DefaultCommandRouter` (CLI wiring helper) and exported it via `src/src.dart`.
- Runner now depends on the core `PluginResolver` abstraction rather than a concrete registry.
- `PluginRegistry` implements `PluginResolver` (no behavior change).
- New port: `WorkspaceConfig` for workspace configuration IO (read/write `mono.yaml`, `monocfg/*`).
  - Added types: `LoadedRootConfig`, `PackageRecord`.
- New: `DefaultTaskExecutor` implementation of core `TaskExecutor`.
  - Centralizes env → target → plan → run and dry-run output.
  - Emits "No packages found. Run `mono scan` first." when workspace is empty.
  - Uses optional `dryRunLabel` so task dry-run uses user task names.

## 0.0.3

- Plugins: added `FormatPlugin` (format, format:check) and `TestPlugin` (test).
- Added comprehensive test coverage for all ports and functionality.

## 0.0.2

- Add filesystem-backed configuration utilities:
  - `FileListConfigFolder` for folder-of-lists stores.
  - `FileGroupStore` adapter scoped to `monocfg/groups/`.
  - `DefaultSlugNamePolicy` for robust group name normalization/validation.
- Prompt UX: `ConsolePrompter.checklist` now handles Enter (CR/LF) and cancel via `SelectionError`; always restores TTY modes.
- Exports: surfaced new system_io modules to consumers via `src/src.dart`.

## 0.0.1

- Initial release with exports and implementations for the Mono CLI
