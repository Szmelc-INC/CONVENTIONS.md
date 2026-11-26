---
id: conventions.github.deployments.webui-style
---
# Web UI style
> Load when: building or restyling a project web page, Pages site or web UI.

- Reference look: follow the project's published design reference, if one exists.
- Architecture, routing, overlays and keys: `CONVENTIONS/INTERFACES/WEBUI/ARCHITECTURE.md` and its siblings. Components: `CONVENTIONS/INTERFACES/WEBUI/COMPONENTS.md`. Accessibility: `CONVENTIONS/INTERFACES/WEBUI/ACCESSIBILITY.md`.
- Colors only from `CONVENTIONS/DESIGN/COLORS.md`, as CSS custom properties on `:root`, overridden per `[data-theme]`.
- Themes: `dark` (default), `light`; optional `mono` (greys and silver, no accent hue) and `terminal` (near-black, accent-text headings and links).
- Theme: `data-theme` on `<html>` set before first paint; cycle item in `[MENU]` + `t` key; choice in `localStorage` inside `try`/`catch`; first visit follows `prefers-color-scheme`, else dark.
- Monospace everywhere: `"JetBrains Mono", ui-monospace, "Cascadia Mono", Menlo, Consolas, monospace`; never fetch webfonts.
- Flat mono/material look: 1px lines, radius 0–4px; no gradients (except the modal vignette and carousel edge-fade masks), glassmorphism or heavy shadows.
- Depth by shade, not size: step the surface and line ramps of `COLORS.md` per level (page, panel, header band, hover, raised); groups are framed panels, an opened item is a sunken reading well with an accent edge.
- Type: 14px base, 13–13.5px body copy at line-height 1.6–1.7, nothing under 11.5px; reading width ≤ 92ch.
- Icons: inline SVG with `currentColor`, 14–16px, defined once (sprite); registry icons inlined at build time as filled paths; no icon fonts, `<img>` icons or icon CDNs; never brand colors.
- Effects stay subtle (hover underline or glow, blinking cursor, carousel glide, `terminal` faint scanlines); none under `prefers-reduced-motion: reduce`.
