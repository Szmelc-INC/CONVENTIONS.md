# Colors
> Load when: any UI, TUI, CLI color, web page, theme, badge or graphic.

| Role | Value | Use |
|---|---|---|
| Accent | `{{profile.colors.accent}}` | On dark: fill + white text |
| Accent text/links | `{{profile.colors.accent_text}}` | Text, links |
| Danger/experimental | `{{profile.colors.danger}}` / `{{profile.colors.danger_text}}` | Errors, warnings, experimental |
| Secondary | `{{profile.colors.secondary}}` | Secondary |
| Highlight | `{{profile.colors.highlight}}` | Limited emphasis, black text |
| Neutrals | Per profile | Everything else |

Shade ramps (UIs with layers; all derived from the values above):

| Ramp | Steps | Use |
|---|---|---|
| Surfaces | Profile surface ramp | One step per nesting level or state |
| Lines | Profile line ramp | Input edges need 3:1 |
| Text | Profile text ramp | Muted and up pass AA on every surface |
| Accent | Profile accent ramp | Use the profile's accessible accent for links, lines and icons |
| Danger | Profile danger ramp | Use the profile's accessible danger for warnings and errors |
| Tints | Profile accent or danger mixed into the background | Selection, active index item, filter hits |
| Light ramp | Profile light ramp | Light toggle; use the profile's accessible accent for links |

- Use the profile palette; dark or light defaults are per profile. Never use a framework's default accent.
- Neutrals carry no blue or green tint.
- Text meets WCAG AA (4.5:1) on the surface it sits on; check raised and hover surfaces too, not only the page.
- Badges, banners and shields use the profile palette; Shields.io params omit `#`.
- Brand icons and logos: Simple Icons (<https://simpleicons.org/>) at a pinned version, monochrome `currentColor`, never brand colors; per-icon license absent or CC0, else leave it out.
- If the project has config, make colors configurable.
