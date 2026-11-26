# CLI
> Load when: building or changing a command-line tool.

- One binary, one entry point, rich subcommands + flags + config file (`CONVENTIONS/INTERFACES/CONFIG.md`).
- Colored per-command help; aligned tables. Colors: `CONVENTIONS/DESIGN/COLORS.md`.
- Message prefixes: `::` info, `==>` step, `✓` ok, `!!` warn, `✗` error. Messages to stderr, data to stdout.
- `--no-color` and `NO_COLOR`; plain output when stdout is not a TTY.
- `--json` for data output.
- Exit codes: `0` ok, `1` error, `2` usage error.
- `completion <shell>` + installed zsh/bash/fish completion files, generated from the command registry.
- Destructive commands confirm (or take `--yes`) and support `--dry-run`.
- Root: `{{profile.privilege_tool}}` for the one step that needs it; never use an unsafe privilege shortcut.
- Has a CLI → also needs a TUI: `CONVENTIONS/INTERFACES/TUI.md`.
