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
