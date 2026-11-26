---
id: conventions.experimental.localization
---
# Localization (en + pl)
> Load when: user opts into experimental conventions, or adds user-facing strings, locales or translations.

Proposal from draft v2.

- English: source code, identifiers, schemas, comments, technical specs. Always.
- Polish: user-facing strings (CLI/TUI/WebUI labels, Discord embeds) via locale packs `locales/en.json` + `locales/pl.json`.
- Locale switch never changes logic; missing key falls back to English.
- Machine-translate drafts (`translate-shell`), then review by a native speaker before release.
