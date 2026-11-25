# Web UI style
> Load when: building or restyling a Szmelc web page, Pages site or web UI.

- Reference look: <https://szmelc-inc.github.io/SAUR/>.
- Colors only from `CONVENTIONS/DESIGN/COLORS.md`, as CSS custom properties on `:root`, overridden per `[data-theme]`.
- Themes: `dark` (default), `light`; optional `mono` (greys and silver, no accent hue) and `terminal` (near-black, accent-text headings and links).
- Theme: `data-theme` on `<html>` set before first paint; cycle button + `t` key; choice in `localStorage` inside `try`/`catch`; first visit follows `prefers-color-scheme`, else dark.
- Monospace everywhere: `"JetBrains Mono", ui-monospace, "Cascadia Mono", Menlo, Consolas, monospace`; never fetch webfonts.
- Flat mono/material look: 1px lines `#262626`, radius 0–4px; no gradients, glassmorphism or heavy shadows.
- Header: small `h1` (≤ 1.5rem, no hero) with a small byline tag, accent top rule (`border-top` 3–4px accent), icon link row, stats row of counts.
- Navigation: folder-style tabs; keys `/` focus filter, `1`–`9` switch tabs, `t` theme, `esc` clear/close; deep links `#<path>` restore the view on load.
- Nested categories: collapsible groups with counts, category index (sidebar when wide, collapsible when narrow), deep link per group.
- Install: one copyable command block with a copy button; copy feedback swaps the icon to a check for ~1s.
- Icons: inline SVG with `currentColor`, 14–16px, defined once (sprite); no icon fonts or icon CDNs.
- Effects stay subtle (hover underline or glow, blinking cursor, `terminal` faint scanlines); none under `prefers-reduced-motion: reduce`.
- Contrast WCAG AA in every theme; visible keyboard focus.
- No tracking, analytics or cookies; external JS only when unavoidable, from a CDN URL pinned to an exact version with `integrity`.
- Works at 360px width: no horizontal page scroll; wide tables and code scroll inside their own box.
