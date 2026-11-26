---
id: conventions.interfaces.webui.theme
---
# Web UI theme
> Load when: choosing colors, themes, typography or visual effects for a web UI.

- Use colors only from `CONVENTIONS/DESIGN/COLORS.md` as CSS custom properties on `:root`, overridden per `[data-theme]`.
- Follow the project's published design reference when one exists.
- Provide `dark` (default) and `light` themes; `mono` (greys and silver, no accent hue) and `terminal` (near-black, accent-text headings and links) are optional.
- Set `data-theme` on `<html>` before first paint; expose theme choice in `[MENU]` and on `t`; save it in `localStorage` inside `try`/`catch`; on first visit follow `prefers-color-scheme`, else use dark.
- Use `"JetBrains Mono", ui-monospace, "Cascadia Mono", Menlo, Consolas, monospace`; never fetch webfonts.
- Use a flat mono/material look: 1px lines, 0–4px radius, no gradients except modal vignette and carousel edge-fade masks, no glassmorphism or heavy shadows.
- Show depth through the surface and line ramps in `CONVENTIONS/DESIGN/COLORS.md`; frame groups as panels and give an opened item a sunken reading well with an accent edge.
- Set body text to 14px, copy to 13–13.5px at line-height 1.6–1.7, minimum text to 11.5px and reading width to 92ch.
