# Interoperability matrix

The compiler preserves one file per rule and maps `scope` to host-native path selection when the host supports it. Natural-language `Load when` text remains a description. It is not converted into invented globs. Hosts without a selective native loader receive on-demand references or a documented one-shot fallback.

| Tool | Native mechanism | Lazy mapping | No-scope behavior |
|---|---|---|---|
| Nested AGENTS.md | Directory instruction files | Place scoped rule in each matching directory's `AGENTS.md` | Skill pack and root catalog; natural-language trigger is a hint |
| Agent Skills | One `SKILL.md` per pack | Pack description selects the skill; rule catalog selects the matching rule | Same; skill loading is on demand |
| Cursor | `.cursor/rules/*.mdc` | `globs` from `scope`; `alwaysApply: false` | Description based on trigger; model requested |
| Copilot | `.github/instructions/*.instructions.md` | `applyTo` from `scope` | No native prompt-selected rule file. Emit a named on-demand artifact and catalog link |
| Kiro | `.kiro/steering/*.md` | `inclusion: fileMatch`, `fileMatchPattern` from scope | `inclusion: auto` with the rule trigger as description |
| Windsurf | `.windsurf/rules/*.md` | `trigger: glob`, `globs` from scope | `trigger: model_decision` |
| Cline | `.clinerules/*.md` | `paths` array from `scope` | No file trigger. Emit a named on-demand artifact and catalog link |
| Continue | `.continue/rules/*.md` | `globs` from scope and `alwaysApply: false` | Description-driven selection |
| aider | `--read FILE` | Not supported: `--read` adds selected read-only files and has no trigger expression | Emit one command per rule. User selects a matching read |
| Gemini | `GEMINI.md` files | Put scoped rules in directory-level files for just-in-time discovery | Keep only a catalog in root `GEMINI.md`; do not import every rule |
| Codex | Nested `AGENTS.md` and Skills | Use nested instructions for scope | One skill per pack, invoked by its description |

Adapters MUST announce when a host cannot express a rule's exact trigger. They MUST NOT change the rule's meaning to fit the host.

Official references: [AGENTS.md](https://agents.md/), [Agent Skills](https://agentskills.io/specification), [Cursor rules](https://docs.cursor.com/context/rules), [Copilot custom instructions](https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions), [Kiro steering](https://kiro.dev/docs/steering/), [Windsurf rules](https://docs.windsurf.com/windsurf/cascade/memories), [Cline rules](https://github.com/cline/cline/blob/main/docs/customization/cline-rules.mdx), [Continue rules](https://docs.continue.dev/customize/deep-dives/rules), [aider `--read`](https://aider.chat/docs/config/options), [Gemini CLI context files](https://geminicli.com/docs/cli/gemini-md/), and [Codex AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md).
