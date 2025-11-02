## 0.0.2

- Add filesystem-backed configuration utilities:
  - `FileListConfigFolder` for folder-of-lists stores.
  - `FileGroupStore` adapter scoped to `monocfg/groups/`.
  - `DefaultSlugNamePolicy` for robust group name normalization/validation.
- Prompt UX: `ConsolePrompter.checklist` now handles Enter (CR/LF) and cancel via `SelectionError`; always restores TTY modes.
- Exports: surfaced new system_io modules to consumers via `src/src.dart`.

## 0.0.1

- Initial release with exports and implementations for the Mono CLI
