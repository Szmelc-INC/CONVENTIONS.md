---
id: conventions.experimental.cli-contract
---
# v2 CLI & config contract
> Load when: user opts into experimental conventions, or makes a tool wrappable by another tool or agent.

Proposal from the v2 draft (2026-11-25), extending `CONVENTIONS/INTERFACES/CLI.md` and `CONVENTIONS/INTERFACES/CONFIG.md`.

- `--json` on every read command, so wrappers never parse text.
- Exit code `3` = partial success (some items failed, the rest done).
- Config validated against a JSON Schema shipped with the tool.
- Shared config root `${XDG_CONFIG_HOME:-~/.config}/szmelc/<tool>/`; the old path stays a read fallback during migration.
- Split config: one file or `config.d/*.toml` deep-merged in lexical order; scalars last-wins, tables merge, arrays append unless the key ends in `!` (replace).
- Every write command accepts an idempotency key or is naturally idempotent; running it twice never does the work twice.
