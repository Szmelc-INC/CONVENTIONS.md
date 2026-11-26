# Web UI style
> Load when: building or restyling a Szmelc web page, Pages site or web UI.

- Reference look: <https://szmelc-inc.github.io/SAUR/>.
- Colors only from `CONVENTIONS/DESIGN/COLORS.md`, as CSS custom properties on `:root`, overridden per `[data-theme]`.
- Themes: `dark` (default), `light`; optional `mono` (greys and silver, no accent hue) and `terminal` (near-black, accent-text headings and links).
- Theme: `data-theme` on `<html>` set before first paint; cycle button + `t` key; choice in `localStorage` inside `try`/`catch`; first visit follows `prefers-color-scheme`, else dark.
- Monospace everywhere: `"JetBrains Mono", ui-monospace, "Cascadia Mono", Menlo, Consolas, monospace`; never fetch webfonts.
- Flat mono/material look: 1px lines, radius 0–4px; no gradients, glassmorphism or heavy shadows.
- Depth by shade, not size: step the surface and line ramps of `COLORS.md` per level (page, panel, header band, hover, raised); groups are framed panels, an opened item is a sunken reading well with an accent edge.
- Type: 14px base, 13–13.5px body copy at line-height 1.6–1.7, nothing under 11.5px; reading width ≤ 92ch.
- Header: centered `h1` (≤ 2.5rem, no hero, no tagline under it), accent top rule (`border-top` 3–4px accent); below it a centered icon link row with the theme toggle between full-width 1px rules; byline in the footer.
- Navbar order: title, link row, tabs (stretched to the full width), filter; intro (tagline, stats, install) is a panel below the toolbar.
- Navigation: folder-style tabs and the filter in a sticky toolbar; keys `/` focus filter, `1`–`9` switch tabs, arrows/`Home`/`End` inside the tab list, `t` theme, `esc` clear/close; deep links `#<path>` restore the view on load and clear the toolbar (`scroll-margin-top`).
- Filter: highlights hits with `<mark>` (accent tint), flags tabs with hits, announces the count in an `aria-live` status.
- Nested categories: collapsible groups with counts, category index (sidebar when wide, collapsible when narrow), deep link per group.
- Install: one copyable command block with a copy button; copy feedback swaps the icon to a check for ~1s.
- Icons: inline SVG with `currentColor`, 14–16px, defined once (sprite); no icon fonts or icon CDNs.
- Effects stay subtle (hover underline or glow, blinking cursor, `terminal` faint scanlines); none under `prefers-reduced-motion: reduce`.
- Contrast WCAG AA in every theme; visible keyboard focus; targets ≥ 26px tall.
- Accessibility: skip link, tabs with `role=tab`/`tabpanel`, `aria-current` on the active index item; `prefers-contrast: more` raises muted text and lines; `forced-colors` keeps selection visible.
- No tracking, analytics or cookies; external JS only when unavoidable, from a CDN URL pinned to an exact version with `integrity`.
- Works at 360px width: no horizontal page scroll; wide tables and code scroll inside their own box.
