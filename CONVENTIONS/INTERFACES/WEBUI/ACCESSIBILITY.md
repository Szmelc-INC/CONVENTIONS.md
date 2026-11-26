---
id: conventions.interfaces.webui.accessibility
---
# Web UI accessibility
> Load when: checking or fixing contrast, focus, screen-reader support or the small-screen layout of a web UI.

- Contrast WCAG AA in every theme; visible keyboard focus; targets ≥ 26px tall.
- Accessibility: skip link, tabs with `role=tab`/`tabpanel`, `aria-current` on the active index item; `prefers-contrast: more` raises muted text and lines; `forced-colors` keeps selection visible.
- Works at 360px width: no horizontal page scroll; wide tables and code scroll inside their own box.
- Every interactive element has a visible label or an `aria-label`. Icon-only buttons carry a `title` as well.
- Check each theme with `prefers-contrast: more`, `forced-colors: active` and `prefers-reduced-motion: reduce` emulated.
