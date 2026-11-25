# Configuration
> Load when: adding a config file, options, env vars, or storage paths to a tool.

- Human-edited: TOML, every option commented with its default. Machine-written: strict JSON (reject unknown keys).
- Avoid YAML for authored config (whitespace and type footguns); use it only where a tool demands it.
- Precedence, later wins: built-in defaults < config file < `*.local.*` override (gitignored) < env `TOOL_*` < flags.
- XDG paths: config `${XDG_CONFIG_HOME:-~/.config}/<tool>/`, data `${XDG_DATA_HOME:-~/.local/share}/<tool>/`, cache and state likewise. Shipped defaults stay separate from the user layer.
- Runs with zero config; an option exists only where two real users need different behavior.
- Validate on load; invalid → a clear error naming file and key, nothing applied. Never guess or coerce.
- Secrets never in config: reference an env var, file path or keyring entry by name.
- Local persistence: SQLite (WAL) when there is real data, else a plain file.
- Colors configurable when the project has config (`CONVENTIONS/design/colors.md`).
