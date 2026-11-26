---
id: conventions.formats.toml
---
# TOML
> Load when: writing or parsing a TOML file.

- TOML 1.0; default format for human-edited config, every key commented (`CONVENTIONS/INTERFACES/CONFIG.md`).
- Keys `snake_case` (`CONVENTIONS/CODE/NAMING.md`); bare keys, quoted only when required.
- `[table]` sections over inline tables; inline tables only for short one-line values.
- Arrays of records as `[[array]]`, not nested inline arrays.
- Dates and times as TOML datetimes (RFC 3339), never strings.
- Durations and sizes carry units: a string (`"30s"`, `"10MiB"`) or a key suffix (`timeout_secs`).
