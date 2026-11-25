# Colors
> Load when: any UI, TUI, CLI color, web page, theme, badge or graphic.

| Role | Value | Use |
|---|---|---|
| Accent | `#105c5c` | On dark: fill + white text |
| Accent text/links | `#1f8a8a` | Text, links |
| Danger/experimental | `#750f0f` / `#b83a3a` text | Errors, warnings, experimental |
| Silver | `#c0c0c0` | Secondary |
| Aquamarine | `#7fffd4` | Max 1–2 highlights per screen, black text |
| Neutrals | `#0b0b0b` `#131313` `#1b1b1b`, lines `#262626` | Everything else |
| Light neutrals | `#f3f3f3` `#ffffff` `#e9e9e9`, lines `#d6d6d6`, text `#141414` | Light toggle only |

- Dark by default; light only as a toggle. Never purple, never a framework's default accent.
- Neutrals carry no blue or green tint.
- Badges, banners and shields use the same palette: `105c5c` fill, `c0c0c0` for secondary values, `750f0f` for experimental.
- Project has config → make colors configurable.
