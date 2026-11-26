---
id: conventions.interfaces.webui.accessibility
---
# Web UI accessibility
> Load when: making a web UI usable with keyboard, assistive technology or accessibility preferences.

- Meet WCAG AA contrast in every theme, show keyboard focus and make targets at least 26px tall.
- Add a skip link; use `role="tab"` and `tabpanel` for tabs and `aria-current` on the active index item.
- Under `prefers-contrast: more`, raise muted text and line contrast; keep selection visible in `forced-colors` mode.
- Keep effects subtle (hover underline or glow, blinking cursor, carousel glide, faint terminal scanlines) and disable them under `prefers-reduced-motion: reduce`.
- Do not track users or use analytics or cookies; load external JavaScript only when unavoidable, from an exact-version CDN URL with `integrity`.
- Give every interactive element a visible label or an `aria-label`; add a `title` to icon-only buttons.
- Check each theme with `prefers-contrast: more`, `forced-colors: active` and `prefers-reduced-motion: reduce` emulated.
