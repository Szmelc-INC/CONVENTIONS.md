# Web UI style
> Load when: building or restyling a Szmelc™ web page, Pages site or web UI.

- Reference look: <https://szmelc-inc.github.io/SAUR/>.
- Colors only from `CONVENTIONS/DESIGN/COLORS.md`, as CSS custom properties on `:root`, overridden per `[data-theme]`.
- Themes: `dark` (default), `light`; optional `mono` (greys and silver, no accent hue) and `terminal` (near-black, accent-text headings and links).
- Theme: `data-theme` on `<html>` set before first paint; cycle item in `[MENU]` + `t` key; choice in `localStorage` inside `try`/`catch`; first visit follows `prefers-color-scheme`, else dark.
- Monospace everywhere: `"JetBrains Mono", ui-monospace, "Cascadia Mono", Menlo, Consolas, monospace`; never fetch webfonts.
- Flat mono/material look: 1px lines, radius 0–4px; no gradients (except the modal vignette and carousel edge-fade masks), glassmorphism or heavy shadows.
- Depth by shade, not size: step the surface and line ramps of `COLORS.md` per level (page, panel, header band, hover, raised); groups are framed panels, an opened item is a sunken reading well with an accent edge.
- Type: 14px base, 13–13.5px body copy at line-height 1.6–1.7, nothing under 11.5px; reading width ≤ 92ch.
- Header: centered one-line `h1` (≤ 3.3rem, `vw`-scaled to fit 320px, no wrap, no hero, no tagline under it) with a `❯` prompt glyph, accent top rule (`border-top` 3–4px accent); byline in the footer.
- Navbar order: title, "Compatible with" carousel (hidden while empty), tabs (stretched to the full width), filter.
- Carousel: registry entries only, icon or monogram + name, small muted label; one slow continuous glide driven by `requestAnimationFrame` (left; 1% of page loads right), looped seamlessly by `aria-hidden` clones with `tabindex=-1`; hover, keyboard focus or touch ease it to a stop, then wheel, trackpad, drag or swipe scroll it by hand and it wraps; leaving eases it back; paused while the tab is hidden; edge-fade masks; `prefers-reduced-motion: reduce` → static scrollable row, no clones.
- Compat popup (click/`Enter` on an item or a rule chip, deep link `#compat/<id>`): icon or monogram, name, kind, description, compatible version, versioning note (pinned or unversioned upstream), added and updated dates, covering rules linked to `#<path>`, external links in a new tab, the registry disclaimer in small muted text.
- Origin sub-tabs `All · Third-party · Szmelc™`: segmented, same look as the folder tabs, shown only on tabs with origin-tagged rules; filter that tab's rules (other items hide unless All), combine with the text filter, update tab count and filter status; rows carry a `3rd-party`/`Szmelc™` badge, third-party rows their registry chips (a mouse shortcut in the row; real links in the opened body).
- `[MENU]` in the top-right corner: disclosure button (`aria-expanded`/`aria-controls`) opening a list of actions (star, install, theme) and links; arrows/`Home`/`End` move, closes on outside click, `esc`, Tab out and item activation.
- Modal: one native `<dialog>` (`showModal()`), vignette `::backdrop`; closes on `esc`, backdrop click and a close button; focus returns to the opener; scrolls inside at 320px.
- Navigation: folder-style tabs and the filter in a sticky toolbar; keys `/` focus filter, `1`–`9` and `0` (10th) switch tabs, arrows/`Home`/`End` inside the tab list, `t` theme, `esc` closes menu or modal first, then clears the filter; single-key shortcuts are off while the menu or modal is open or focus is in the carousel (arrows move between its items); deep links `#<path>` restore the view on load and clear the toolbar (`scroll-margin-top`).
- Filter: highlights hits with `<mark>` (accent tint), flags tabs with hits, announces the count in an `aria-live` status.
- Nested categories: collapsible groups with counts, category index (sidebar when wide, collapsible when narrow), deep link per group.
- Install: intro (tagline, stats, one copyable command block that wraps instead of clipping) in the modal, opened from `[MENU]` or deep link `#install`; copy feedback swaps the icon to a check for ~1s.
- Icons: inline SVG with `currentColor`, 14–16px, defined once (sprite); registry icons inlined at build time as filled paths; no icon fonts, `<img>` icons or icon CDNs; never brand colors.
- Effects stay subtle (hover underline or glow, blinking cursor, carousel glide, `terminal` faint scanlines); none under `prefers-reduced-motion: reduce`.
- Contrast WCAG AA in every theme; visible keyboard focus; targets ≥ 26px tall.
- Accessibility: skip link, tabs with `role=tab`/`tabpanel`, `aria-current` on the active index item; `prefers-contrast: more` raises muted text and lines; `forced-colors` keeps selection visible.
- No tracking, analytics or cookies; external JS only when unavoidable, from a CDN URL pinned to an exact version with `integrity`.
- Works at 360px width: no horizontal page scroll; wide tables and code scroll inside their own box.
