# Repository layout
> Load when: creating a repo, adding top-level files or directories, or auditing a repo against the conventions.

| File | When | Job |
|---|---|---|
| `README.md` | always | What it is, one-line install, usage, how it works (`CONVENTIONS/SPECS/THIRD-PARTY/README-MD.md`) |
| `LICENSE` | always | `CONVENTIONS/GITHUB/REPO/METADATA.md` |
| `AGENTS.md` + `CLAUDE.md` (`@AGENTS.md`) | always | Working rules for coding agents (`CONVENTIONS/SPECS/THIRD-PARTY/AGENTS-MD.md`) |
| `DESIGN.md` | new projects | The owner's brief (`CONVENTIONS/SPECS/ORIGINAL/DESIGN-MD.md`) |
| `docs/ARCHITECTURE-v<N>.md` | DB, daemon or plugin system | Binding contract per major version |
| `PKGBUILD`, `flake.nix` | anything installable | `CONVENTIONS/PACKAGING/ARCH.md`, `CONVENTIONS/PACKAGING/NIX.md` |
| CI workflow | always | Build the package and run tests on every PR (`CONVENTIONS/GITHUB/ACTIONS/CI.md`) |

- Directories by job: source (`cmd/`, `internal/`, `src/`), `scripts/`, `tests/`, `docs/`, `completions/`; packaging at the root or in a packaging subdirectory.
- One entry point: one command with subcommands, not a pile of loose scripts.
- Features are files: modules, plugins, drivers and addons live in their own directory and can be added, toggled and removed without touching the core.
- Never commit: secrets, machine-local overrides (`*.local.*`), build output, large data or model artefacts. Gitignore them.
- Superseded code moves to a legacy directory or into git history; never leave dead copies next to live ones.
