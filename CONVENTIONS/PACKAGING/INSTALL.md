---
id: conventions.packaging.install
---
# Install & uninstall
> Load when: writing an installer, a setup script, install instructions, or uninstall steps.

- Package first (`{{profile.package_registry}}`, Nix); a script installer only for what a package cannot do (user config, harness links).
- Reversible: ship and document uninstall; it restores what install changed.
- Own one prefix (`~/.local/share/<tool>`, or one folder in portable mode); outside it, touch at most one documented hook line.
- By default, preserve global instruction files and update only a marked block or import line; uninstall removes only that block. A `--replace` option may back up and replace a file only when the user explicitly opts in.
- Idempotent: re-running converges and never duplicates.
- `status` and `--dry-run` show what would change before anything does.
- Verifiable sources: a tag or a signed script, never a branch tip piped into a shell.
- Root: `{{profile.privilege_tool}}` for the one step that needs it, never for the whole script.
- Scripts follow `CONVENTIONS/CODE/SHELL.md`.
