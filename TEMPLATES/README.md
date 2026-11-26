# TEMPLATES
> Load when: starting a new rule, prompt, skill, category or project agent file from a skeleton.

Skeletons to copy. Root `TEMPLATES.md` is the generated map of this core.

| Template | Copy to | When |
|---|---|---|
| `TEMPLATES/rule.md` | `CONVENTIONS/<CATEGORY>/<TOPIC>.md` or `AGENTS/RULES/<TOPIC>.md` | Any new rule file (`CONTRIBUTING/WRITING.md`) |
| `TEMPLATES/prompt.md` | Any prompt, system prompt or agent brief | New prompt (`AGENTS/PROMPT/`) |
| `TEMPLATES/category-README.md` | `CONVENTIONS/<CATEGORY>/README.md` | A category needs more than its table row (optional) |
| `TEMPLATES/SKILL.md` | `AGENTS/skills/<name>/SKILL.md` or a project's skill dir | New agent skill (`CONVENTIONS/SPECS/THIRD-PARTY/SKILL-MD.md`) |
| `TEMPLATES/AGENTS.md` | `<project>/AGENTS.md` | New or adopting project; `install.sh project <dir>` copies it |
| `TEMPLATES/project-README.md` | `<project>/README.md` | New project README (`CONVENTIONS/REPO/DOCS.md`) |
| `TEMPLATES/webui.html` | `<site>/index.html` (build output source) | New web UI or Pages site (`CONVENTIONS/INTERFACES/WEBUI/ARCHITECTURE.md`) |

- Replace every `<placeholder>`; delete sections that stay empty.
- Templates are not rules, skills or adapters: build, check, site and install skip them. The copy is checked: `META/tools/build.sh && META/tools/check.sh`.
- File names stay lowercase or tool-fixed (`SKILL.md`, `AGENTS.md`); installs depend on them.
- New template: add it here and a row in this table.
