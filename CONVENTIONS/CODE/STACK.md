---
id: conventions.code.stack
---
# Stack defaults
> Load when: starting a project or tool, or choosing a language or dependencies.

- Minimal deps: write or cherry-pick the snippet before pulling a library for one small task.
- CLI / TUI / daemons: Go, stdlib-first (`CONVENTIONS/CODE/GO.md`, `CONVENTIONS/INTERFACES/CLI.md`, `CONVENTIONS/INTERFACES/TUI.md`).
- Glue and installers: shell (`CONVENTIONS/CODE/SHELL.md`). Never add a runtime (node, python) for what shell or Go does in a few lines.
- Web UI: static HTML/CSS/JS, no build step to run; frameworks only when the UI really needs them.
- Python only where its ecosystem is the point (ML, data); keep the core light and heavy stacks optional.
- Config-driven and modular where it costs little: behavior in config and plugins, not hardcoded (`CONVENTIONS/INTERFACES/CONFIG.md`).
- Platforms: support order and meaning in `CONVENTIONS/SYSTEMS/SUPPORT.md`; no hardcoded `/home/...` paths.
