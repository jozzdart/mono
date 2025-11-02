## 0.0.4

- Added `CommandEnvironment` abstraction and `CommandEnvironmentBuilder` interface to `ports/`.
- Added `cli/command_router.dart` with `CommandRouter` interface and `CommandHandler` typedef.
- Exported new interfaces from `src/src.dart` for consumers.
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
