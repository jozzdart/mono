# ui/

Layout and styling hints for renderers.

## Layout

- `RegionId`: identifier for a display region.
- `PinnedRegion`: reserved area (e.g., progress section) with optional title.
- `OverlayRegion`: transient region useful for overlays.
- `LayoutHint`: `overlay`, `pinnedBelow`, `pinnedAbove`.

## Styling

- `StyleToken`: semantic tokens (`primary`, `success`, `warning`, `error`,
  `muted`, `accent`, `dim`, `bold`, `italic`, `underline`).
- `StyledText`: text + token set.
- `StyleTheme`: maps `LogLevel`/category to tokens.

## Guidance

- Renderers should degrade gracefully if TTY capabilities are limited.
- Avoid hard-coding ANSI sequences in core; map tokens to UI capabilities.
