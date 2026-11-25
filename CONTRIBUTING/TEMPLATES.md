# Templates
> Load when: starting a new rule, skill, category or project agent file from a skeleton.

| Template | Copy to | When |
|---|---|---|
| `META/templates/rule.md` | `CONVENTIONS/<CATEGORY>/<TOPIC>.md` or `AGENTS/RULES/<TOPIC>.md` | Any new rule file (`CONTRIBUTING/WRITING.md`) |
| `META/templates/category-README.md` | `CONVENTIONS/<CATEGORY>/README.md` | A category needs more than its table row (optional) |
| `META/templates/SKILL.md` | `AGENTS/skills/<name>/SKILL.md` or a project's skill dir | New agent skill (`CONVENTIONS/SPECS/THIRD-PARTY/SKILL-MD.md`) |
| `META/templates/AGENTS.md` | `<project>/AGENTS.md` | New or adopting project; `install.sh project <dir>` copies it |

- Replace every `<placeholder>`; delete sections that stay empty.
- Templates are exempt from rule checks; the copy is not: `META/tools/build.sh && META/tools/check.sh`.
- New template: add it to `META/templates/`, a row here, and the templates line in `META/README.md`.
