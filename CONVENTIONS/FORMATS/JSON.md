# JSON
> Load when: writing, generating or validating a JSON file or JSON output.

- UTF-8 without BOM, 2-space indent, trailing newline.
- Strict JSON: no comments, no trailing commas; JSONC or JSON5 only where the reading tool documents it.
- Generated files: stable key order and formatting, so regeneration diffs only real changes.
- Schema exists → `$schema` key first; write schemas in JSON Schema draft 2020-12.
- Validate in CI: `jq empty <file>` at minimum, plus the schema when one exists (`CONVENTIONS/GITHUB/ACTIONS/CI.md`).
- Machine-written config: `CONVENTIONS/INTERFACES/CONFIG.md`. CLI output: `--json` per `CONVENTIONS/INTERFACES/CLI.md`.
