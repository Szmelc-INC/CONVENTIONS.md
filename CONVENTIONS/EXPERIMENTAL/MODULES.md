---
id: conventions.experimental.modules
---
# Modules (KUR)
> Load when: user opts into experimental conventions, or builds a Kombinat/KUR plugin module.

Proposal from draft v2 (Kombinat).

- Fractal composability: every module runs the same standalone (CLI), combined with others, or inside the full Kombinat mesh.
- Zero hardcode: the core holds only API router, state machine and module loader. UI, Discord bot, locales, fleet are toggleable plugins.
- Declarative state: all runtime behavior lives in `config.toml` / `config.json`. No hidden state.
- One schema drives CLI flags, TUI and WebUI; interfaces are never hand-wired per frontend.
- Agents read `MODULE.md` before touching a module; agent tools are limited to the module's declared skills (least privilege).

Module skeleton:
```text
<module>/
├── MODULE.md            docs, config schema, agent setup prompt
├── SKILL.md             agent-callable capabilities
├── ASSERTIONS.md        deterministic validation rules
├── config.default.toml  exhaustive defaults
├── src/                 Go / PHP / POSIX shell
├── ui/                  WebUI / TUI / Discord bindings
└── locales/             en.json, pl.json
```
