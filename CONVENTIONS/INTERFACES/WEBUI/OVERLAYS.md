---
id: conventions.interfaces.webui.overlays
---
# Web UI overlays
> Load when: adding a modal, popup, menu, copy button or share action to a web UI.

- One native `<dialog>` per page, reused through one `openModal({title, html, opener, onClose})`. Open it with `showModal()`.
- The dialog closes on `Esc`, on a backdrop click and on its close button. Focus returns to the opener.
- Popup content comes from the build-time data object. No fetch to open a popup.
- Menu: a disclosure button (`aria-expanded`, `aria-controls`) and a list. Arrows, `Home` and `End` move. It closes on an outside click, `Esc` and Tab out.
- The modal stacks over the menu. `Esc` closes the top layer first.
- Every overlay has a transient deep link (`CONVENTIONS/INTERFACES/WEBUI/ROUTING.md`).
- Copy buttons copy the literal value, swap the icon to a check for about 1 s, and stay unchanged on failure.
- Share: the page URL with the current hash, a copy button and plain links. No third-party share scripts.
- The dialog scrolls inside itself at 360px width. The page behind it does not scroll.
