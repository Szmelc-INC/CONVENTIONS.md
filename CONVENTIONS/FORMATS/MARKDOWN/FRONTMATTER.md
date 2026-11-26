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
- Rule files take header lines, not frontmatter (`CONVENTIONS/SPECS/ORIGINAL/RULE-FILES.md`).
