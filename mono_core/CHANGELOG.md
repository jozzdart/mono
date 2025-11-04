## 0.0.8

- Removed `ConfigValidator` and `SchemaProvider`

## 0.0.7

- New: `Logger` extension helpers (`info`, `warn`, `error`, `success`, `debug`, `header`, `divider`) exported via `src/src.dart`.
- Added `LoggerSettings` type and `MonoConfig.logger` field.

## 0.0.6

- New port: `CliEngine` for CLI runtime abstraction.
- Added `CommandRouterFactory` typedef and updated `CliEngine.run` to accept router factory.

## 0.0.5

- Breaking: Replaced IOSink-based IO in core ports with `Logger`.
  - `CommandHandler` now takes `{ required CliInvocation inv, required Logger logger }`.
  - `CommandRouter.tryDispatch` now requires a `Logger` instead of `out`/`err`.
  - `TaskExecutor.execute` now requires a `Logger` instead of `out`/`err`.
  - Tests updated to use in-memory `Logger` doubles.

## 0.0.4

- Added `CommandEnvironment` abstraction and `CommandEnvironmentBuilder` interface to `ports/`.
- Added `CommandRouter` interface and `CommandHandler` typedef.
- Added `PluginResolver` abstraction for resolving `TaskPlugin` by `PluginId`.
- New port: `WorkspaceConfig` for workspace configuration IO (read/write `mono.yaml`, `monocfg/*`).
  - Added types: `LoadedRootConfig`, `PackageRecord`.
- New port: `TaskExecutor` to centralize env → target → plan → run flow.
  - Added optional `dryRunLabel` parameter to match user-facing task names in dry-run output.
- No behavior change; enables cleaner layering and reuse across CLI implementations.

## 0.0.3

- Added comprehensive test coverage for all core functionality.

## 0.0.2

- New ports to support folder-of-lists configuration patterns:
  - `NamePolicy`
  - `ListConfigFolder`
  - `GroupStore`
- Exports: added the new ports to `src/src.dart`.
- No breaking API changes.

## 0.0.1

- Initial release with core functionality for the Mono CLI
