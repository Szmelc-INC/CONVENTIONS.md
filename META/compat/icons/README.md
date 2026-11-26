# Compatibility icons
Monochrome brand icons for `META/compat/registry.toml`, shown in the site's compatibility list.

- Source: Simple Icons 16.38.1 <https://simpleicons.org/>, files `icons/<slug>.svg` unchanged except `fill="currentColor"` on the root element.
- License: CC0 1.0 for the icon files (<https://github.com/simple-icons/simple-icons/blob/develop/LICENSE.md>). The marks stay trademarks of their owners; disclaimer: `disclaimer` in `META/compat/registry.toml`.
- Rules: one 24x24 path, `fill="currentColor"`, no brand colors, no `style`, scripts or event attributes (`META/tools/check.sh`). No icon upstream → omit `icon`; the UI shows a monogram.
- New icon: take the slug from the pinned Simple Icons version, add the root fill, reference it from one registry entry.
