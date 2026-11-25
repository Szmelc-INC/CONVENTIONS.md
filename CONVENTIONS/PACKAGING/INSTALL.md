# Install & uninstall
> Load when: writing an installer, a setup script, install instructions, or uninstall steps.

- Package first (SAUR, Nix); a script installer only for what a package cannot do (user config, harness links).
- Reversible: ship and document uninstall; it restores what install changed.
- Own one prefix (`~/.local/share/<tool>`, or one folder in portable mode); outside it, touch at most one documented hook line.
- Never overwrite user files: move them to `*.bak.<timestamp>` and restore them on uninstall.
- Idempotent: re-running converges and never duplicates.
- `status` and `--dry-run` show what would change before anything does.
- Verifiable sources: a tag or a signed script, never a branch tip piped into a shell.
- Root: `pkexec` for the one step that needs it, never for the whole script.
- Scripts follow `CONVENTIONS/CODE/SHELL.md`.
