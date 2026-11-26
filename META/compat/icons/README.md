# Compatibility icons
Monochrome brand icons for `META/compat/registry.toml`, shown in the site's compatibility list.

- Source: Simple Icons 16.38.1 <https://simpleicons.org/>, files `icons/<slug>.svg` unchanged except `fill="currentColor"` on the root element.
- License: CC0 1.0 (<https://github.com/simple-icons/simple-icons/blob/develop/LICENSE.md>). Only icons without a per-icon `license` in Simple Icons' `data/simple-icons.json`, or with CC0-1.0 (Markdown), are vendored. MIT or CC-BY icons (Conventional Commits, GitHub Copilot, GNU Bash, NixOS) are left out. The marks stay trademarks of their owners. Disclaimer: `disclaimer` in `META/compat/registry.toml`.
- Rules: one 24x24 path, `fill="currentColor"`, no brand colors, no `style`, scripts or event attributes (`META/tools/check.sh`). No icon upstream → omit `icon`. The UI shows a monogram.
- New icon: take the slug from the pinned Simple Icons version, confirm its per-icon license is absent or CC0, add the root fill, reference it from a registry entry.
