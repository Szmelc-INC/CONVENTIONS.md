---
id: conventions.interfaces.webui.keyboard
---
# Web UI keyboard
> Load when: adding keyboard shortcuts or keyboard navigation to a web UI.

- One `keydown` listener on `window` owns the single-key shortcuts. It ignores events with Ctrl, Meta or Alt.
- Gate order: modal open, the dialog owns the keys. Menu open, only `Esc`. Focus in a widget with its own keys (tab list, carousel), the widget. Focus in a text field, only `Esc`.
- Default map: `/` focus the filter, `1`–`9` and `0` switch views, `t` theme, `e` expand all, `?` key help, `Esc` close the top layer, then clear the filter.
- Widgets follow the WAI-ARIA patterns (<https://www.w3.org/WAI/ARIA/apg/patterns/>): tabs and menus move with arrows, `Home` and `End`.
- Every shortcut has a visible control. Key help lists the map from the same table that the handler reads.
- Never bind keys that the browser or a screen reader reserves: Ctrl/Cmd combinations, Tab, Space outside buttons.
- Focus is always visible. After a view switch, focus stays on the control that caused it.
