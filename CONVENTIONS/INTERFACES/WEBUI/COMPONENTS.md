---
id: conventions.interfaces.webui.components
---
# Web UI components
> Load when: building a carousel, filter, menu, modal, popup, install panel or icon set for a web UI.

- Show the "Compatible with" carousel only when it has registry entries; include an icon or monogram, name and muted label.
- Drive one slow continuous carousel glide with `requestAnimationFrame`; move right on 1% of page loads, pause while hidden and ease back after interaction.
- Use seamless `aria-hidden` clones with `tabindex="-1"` and edge-fade masks; hover, focus or touch eases the glide to a stop for wheel, trackpad, drag or swipe scrolling with wraparound.
- Under reduced motion, show a static scrollable carousel without clones.
- Open a compatibility popup by clicking an item or rule chip, pressing `Enter`, or loading `#compat/<id>`; show icon or monogram, name, kind, description, compatible version, versioning note, added and updated dates, covering rules linked by `#<path>`, external links in a new tab and a muted registry disclaimer.
- Show segmented `All · Third-party · {{profile.brand}}` origin tabs only where rules have origin tags; filter that tab's rules, combine with text filtering, update counts and status, badge each row and show third-party registry chips.
- Use a top-right `[MENU]` disclosure with `aria-expanded` and `aria-controls`; arrows, `Home` and `End` move through actions and links; close it on outside click, `Esc`, Tab out or item activation.
- Reuse one native `<dialog>` with a vignette `::backdrop` and `showModal()`; close on `Esc`, backdrop click or close button, return focus to its opener, and scroll inside at 320px.
- Highlight filter hits with accent-tinted `<mark>`, flag matching tabs and announce the result count in an `aria-live` status.
- Put the tagline, stats and one wrapping copyable command block in the install modal; open it from `[MENU]` or `#install`; show the copy icon as a check for about 1s.
- Define 14–16px inline SVG icons once in a sprite with `currentColor`; inline registry icons at build time as filled paths; use no icon fonts, `<img>` icons, icon CDNs or brand colors.
