# Web UI style
> Load when: building or restyling a Szmelc web page, Pages site or web UI.

- Reference look: <https://szmelc-inc.github.io/SAUR/>.
- Colors only from `CONVENTIONS/DESIGN/COLORS.md`, as CSS custom properties on `:root`.
- Dark by default; light via a toggle (`data-theme` on `<html>`), choice kept in `localStorage` inside `try`/`catch`.
- Monospace everywhere: `"JetBrains Mono", ui-monospace, "Cascadia Mono", Menlo, Consolas, monospace`; never fetch webfonts.
- Flat mono/material look: 1px lines `#262626`, radius 0–4px; no gradients, glassmorphism or heavy shadows.
- Header: small `h1` (≤ 1.5rem, no hero), accent top rule (`border-top` 3–4px accent), stats row of counts below.
- Navigation: folder-style tabs; keys `/` focus filter, `1`–`9` switch tabs, `esc` clear/close; deep links `#<path>` restore the view on load.
- Install: one copyable command block with a copy button.
- Icons: inline SVG with `currentColor`; no icon fonts or icon CDNs.
- Effects stay subtle (hover underline or glow, blinking cursor); none under `prefers-reduced-motion: reduce`.
- Contrast WCAG AA in both themes; visible keyboard focus.
- No tracking, analytics or cookies; external JS only when unavoidable, from a CDN URL pinned to an exact version with `integrity`.
- Works at 360px width: no horizontal page scroll; wide tables and code scroll inside their own box.
