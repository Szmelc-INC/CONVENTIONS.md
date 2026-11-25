# Stack defaults
> Load when: starting a project or tool, or choosing a language or dependencies.

- Minimal deps: write or cherry-pick the snippet before pulling a library for one small task.
- CLI / TUI / daemons: Go, stdlib-first (`CONVENTIONS/code/go.md`, `CONVENTIONS/interfaces/cli.md`, `CONVENTIONS/interfaces/tui.md`).
- Glue and installers: shell (`CONVENTIONS/code/shell.md`). Never add a runtime (node, python) for what shell or Go does in a few lines.
- Web UI: static HTML/CSS/JS, no build step to run; frameworks only when the UI really needs them.
- Python only where its ecosystem is the point (ML, data); keep the core light and heavy stacks optional.
- Config-driven and modular where it costs little: behavior in config and plugins, not hardcoded (`CONVENTIONS/interfaces/config.md`).
- Platforms: Arch first (reference, CI-tested), then Nix and other Linux, Windows via WSL2, macOS best effort; no hardcoded `/home/...` paths.
