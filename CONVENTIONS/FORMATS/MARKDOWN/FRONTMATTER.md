---
id: conventions.formats.markdown.frontmatter
---
# Markdown frontmatter
> Load when: adding YAML frontmatter to a Markdown file.

- Only when a tool reads it: skills (`CONVENTIONS/SPECS/THIRD-PARTY/SKILL-MD.md`), Cursor `.mdc`, Copilot `.instructions.md`, Kiro steering, static site generators.
- Fenced by `---` starting on line 1; nothing before it.
- Flat keys with string values unless the tool's schema says otherwise; YAML rules: `CONVENTIONS/FORMATS/YAML.md`.
- Only keys the tool documents; no custom metadata the tool ignores.
- Never secrets, tokens or personal data.
- Ordinary rule files use their rule header (`# Title`, then `> Load when:`) instead of tool frontmatter; their front matter holds only rule keys such as `id` (`CONVENTIONS/SPECS/ORIGINAL/RULE-FILES.md`).

## Minimal SKILL.md

`release-notes/SKILL.md`: `---` on line 1, only the documented `name` and `description` keys, then the body.

```markdown
---
name: release-notes
description: Drafts release notes from merged pull requests. Use when preparing a release, tagging a version, or summarizing changes since the last tag.
---
Collect merged pull requests since the last tag and group them by type.
```
