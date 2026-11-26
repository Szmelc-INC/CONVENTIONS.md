---
id: conventions.interfaces.webui.components
---
# Web UI components
> Load when: adding or restyling a header, navbar, tabs, filter, carousel, popup, menu or install block in a web UI.

Look and themes: `CONVENTIONS/GITHUB/DEPLOYMENTS/WEBUI-STYLE.md`.

- Header: centered one-line `h1` (≤ 3.3rem, `vw`-scaled to fit 320px, no wrap, no hero, no tagline under it) with a `❯` prompt glyph, accent top rule (`border-top` 3–4px accent); byline in the footer.
- Navbar order: title, "Compatible with" carousel (hidden while empty), tabs (stretched to the full width), filter.
- Carousel: registry entries only, icon or monogram + name, small muted label; one slow continuous glide driven by `requestAnimationFrame` (left; 1% of page loads right), looped seamlessly by `aria-hidden` clones with `tabindex=-1`; hover, keyboard focus or touch ease it to a stop, then wheel, trackpad, drag or swipe scroll it by hand and it wraps; leaving eases it back; paused while the tab is hidden; edge-fade masks; `prefers-reduced-motion: reduce` → static scrollable row, no clones.
- Compat popup (click/`Enter` on an item or a rule chip, deep link `#compat/<id>`): icon or monogram, name, kind, description, compatible version, versioning note (pinned or unversioned upstream), added and updated dates, covering rules linked to `#<path>`, external links in a new tab, the registry disclaimer in small muted text.
- Origin sub-tabs `All · Third-party · {{profile.brand}}`: segmented, same look as the folder tabs, shown only on tabs with origin-tagged rules; filter that tab's rules (other items hide unless All), combine with the text filter, update tab count and filter status; rows carry a `3rd-party`/`{{profile.brand}}` badge, third-party rows their registry chips (a mouse shortcut in the row; real links in the opened body).
- `[MENU]` in the top-right corner: a list of actions (star, install, theme) and links. Behaviour: `CONVENTIONS/INTERFACES/WEBUI/OVERLAYS.md`.
- Modal: one native `<dialog>` with a vignette `::backdrop`, scrolling inside at 320px. Behaviour: `CONVENTIONS/INTERFACES/WEBUI/OVERLAYS.md`.
- Navigation: folder-style tabs and the filter in a sticky toolbar. Keys: `CONVENTIONS/INTERFACES/WEBUI/KEYBOARD.md`. Deep links: `CONVENTIONS/INTERFACES/WEBUI/ROUTING.md`.
- Filter: highlights hits with `<mark>` (accent tint), flags tabs with hits, announces the count in an `aria-live` status.
- Nested categories: collapsible groups with counts, category index (sidebar when wide, collapsible when narrow), deep link per group.
- Install: intro (tagline, stats, one copyable command block that wraps instead of clipping) in the modal, opened from `[MENU]` or deep link `#install`; copy feedback swaps the icon to a check for ~1s.
