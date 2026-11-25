# Stack defaults
> Load when: starting a project or tool, or choosing language, dependencies or config format.

- Minimal deps: write or cherry-pick the snippet before pulling a library for one small task.
- CLI / TUI / system glue: Go, stdlib-first (`CONVENTIONS/interfaces/cli.md`, `CONVENTIONS/interfaces/tui.md`); shell (zsh/bash) first-class, python/node secondary.
- Human-edited config: TOML (commented, merges cleanly). Machine config: strict JSON (reject unknown keys).
- Avoid YAML for authored config (whitespace/type footguns); use it only where a tool demands it.
- Local persistence: SQLite ("strap-in", portable) unless a plain file fits.
- Config-driven and modular where it costs little: behaviour in config/plugins, not hardcoded.
