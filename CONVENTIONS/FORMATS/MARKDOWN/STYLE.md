---
id: conventions.formats.markdown.style
---
# Markdown style
> Load when: writing or editing any Markdown file.

- Target GitHub-Flavored Markdown.
- ATX headings (`#`); one `#` per file; never skip a level.
- Bullets with `-`; numbered lists only when order matters.
- Fenced code blocks with a language tag (`sh`, `go`, `toml`, `text`).
- One sentence or rule per line; never hard-wrap mid-sentence (clean diffs).
- No trailing spaces, no `\` or two-space line breaks; a blank line separates blocks.
- Relative links inside a repo; name files and paths in backticks.
- Examples: sibling file `[Tables](TABLES.md)`; heading in this repo `[Checklist](../../../CONTRIBUTING/WRITING.md#checklist)`.
- Language and voice: `CONVENTIONS/REPO/WRITING.md`.
- markdownlint defaults apply, minus line length (MD013) and any rule these lines override.
- Frontmatter, tables, GitHub extras: `CONVENTIONS/FORMATS/MARKDOWN/FRONTMATTER.md`, `CONVENTIONS/FORMATS/MARKDOWN/TABLES.md`, `CONVENTIONS/FORMATS/MARKDOWN/GITHUB-EXTRAS.md`.
