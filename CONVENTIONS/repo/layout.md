# Repository layout
> Load when: creating a repo, adding top-level files or directories, or auditing a repo against the conventions.

| File | When | Job |
|---|---|---|
| `README.md` | always | What it is, one-line install, usage, how it works (`CONVENTIONS/repo/readme.md`) |
| `LICENSE` | always | `CONVENTIONS/repo/metadata.md` |
| `AGENTS.md` + `CLAUDE.md` (`@AGENTS.md`) | always | Working rules for coding agents (`AGENTS/rules/agent-files.md`) |
| `DESIGN.md` | new projects | The owner's brief (`CONVENTIONS/repo/design-docs.md`) |
| `docs/ARCHITECTURE-v<N>.md` | DB, daemon or plugin system | Binding contract per major version |
| `PKGBUILD`, `flake.nix` | anything installable | `CONVENTIONS/packaging/arch.md`, `CONVENTIONS/packaging/nix.md` |
| CI workflow | always | Build the package and run tests on every PR (`CONVENTIONS/workflow/git-pr-ci.md`) |

- Directories by job: source (`cmd/`, `internal/`, `src/`), `scripts/`, `tests/`, `docs/`, `completions/`; packaging at the root or in a packaging subdirectory.
- One entry point: one command with subcommands, not a pile of loose scripts.
- Features are files: modules, plugins, drivers and addons live in their own directory and can be added, toggled and removed without touching the core.
- Never commit: secrets, machine-local overrides (`*.local.*`), build output, large data or model artefacts. Gitignore them.
- Superseded code moves to a legacy directory or into git history; never leave dead copies next to live ones.
