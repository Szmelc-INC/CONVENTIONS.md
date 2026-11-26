---
id: conventions.profiles.overlays
---
# Profile overlays
> Load when: selecting a profile or applying team, project or user-specific rule overrides.

- Precedence is core defaults < organization profile < team overlay < project overlay < user overlay; a later string value replaces the earlier value.
- Put overlays in TOML files with `[overrides]`, `disable = ["<stable-rule-id>"]`, and an optional `[overrides.set]` table of `profile.<variable> = "<value>"` entries.
- Disable rules by stable `id`, never by path; a disabled rule is omitted from generated indexes and bundles.
- Render layers in order with `META/tools/build.sh --profile <name> --team <file> --project <file> --user <file>`; omit unused layers.
- Keep personal settings in the user overlay, team defaults in the team overlay, and repository-specific choices in the project overlay.
- Overlay values are strings; define new variables in the profile template before referencing them in a rule.
