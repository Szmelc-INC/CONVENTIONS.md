---
id: conventions.formats.yaml
---
# YAML
> Load when: writing a GitHub workflow, issue form, compose file, frontmatter, or any YAML a tool requires.

- Only where a tool demands it (Actions workflows, issue forms, compose, frontmatter); never for authored config (`CONVENTIONS/INTERFACES/CONFIG.md`).
- 2-space indent, no tabs; `.yml` unless the tool requires `.yaml`.
- Quote strings that parse as other types: versions (`'3.10'`, else `3.1`), `'on'`/`'off'`/`'yes'`/`'no'` values, leading zeros, `'*'`.
- Workflows: share steps via reusable workflows or composite actions (`CONVENTIONS/GITHUB/ACTIONS/WORKFLOWS.md`), not anchors and aliases.
- Block style over flow style (`[a, b]`), except short lists.
- CI: `actionlint` for workflows, `yamllint` for other YAML.
