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

Shade ramps (UIs with layers; all derived from the values above):

| Ramp | Steps | Use |
|---|---|---|
| Surfaces | `#0b0b0b` page, `#0f0f0f` panel, `#131313` band, `#171717` hover, `#1b1b1b` raised, `#212121` pressed | One step per nesting level or state |
| Lines | `#1c1c1c` row divider, `#262626` frame, `#303030` control, `#3a3a3a` hover; `#666666` input edge | Input edges need 3:1 |
| Text | `#f2f2f2` heading, `#e3e3e3` body, `#c0c0c0` secondary, `#9a9a9a` muted, `#6e6e6e` decoration only | Muted and up pass AA on every surface |
| Accent | `#0a3d3d` `#105c5c` `#167272` `#1f8a8a` `#34a3a3` | `#34a3a3` for link text on surfaces above `#0f0f0f`; `#1f8a8a` for lines and icons |
| Danger | `#4a0a0a` `#750f0f` `#b83a3a` `#dc6464` | `#dc6464` for danger text; `#b83a3a` for lines and icons |
| Tints | accent or danger mixed 10–40% into the background | Selection, active index item, filter hits |
| Light ramp | surfaces `#f3f3f3` `#f8f8f8` `#ffffff` `#ececec` `#e4e4e4`; lines `#e4e4e4` `#d6d6d6` `#cacaca` `#b4b4b4`; text `#0b0b0b` `#141414` `#4a4a4a` `#5c5c5c` | Light toggle; accent text `#105c5c` |

- Dark by default; light only as a toggle. Never purple, never a framework's default accent.
- Neutrals carry no blue or green tint.
- Text meets WCAG AA (4.5:1) on the surface it sits on; check raised and hover surfaces too, not only the page.
- Badges, banners and shields use the same palette: `105c5c` fill, `c0c0c0` for secondary values, `750f0f` for experimental.
- Project has config → make colors configurable.
