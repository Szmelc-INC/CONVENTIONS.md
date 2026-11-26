---
id: conventions.formats.markdown.github-extras
---
# GitHub Markdown extras
> Load when: using alerts, collapsible sections, task lists, diagrams, footnotes, badges or images in Markdown rendered on GitHub.

- Alerts (`> [!NOTE]`, `> [!TIP]`, `> [!IMPORTANT]`, `> [!WARNING]`, `> [!CAUTION]`): sparingly, one or two per page, never stacked.
- `<details><summary>…</summary>` for long optional content (logs, full option lists); never hide install or required steps.
- Task lists (`- [ ]`, `- [x]`) for checklists in issues, PRs and plans.
- Diagrams: a fenced `mermaid` block instead of an image, so it diffs and stays editable.
- Footnotes (`[^1]`) for sources and asides that would break a line.
- No `:emoji:` shortcodes in specs, rules or docs.
- Badges: shields.io in the palette (`CONVENTIONS/DESIGN/COLORS.md`); placement per `CONVENTIONS/SPECS/THIRD-PARTY/README-MD.md`.
- Images: alt text always; `<img src="…" alt="…" width="…">` when size matters.
- Screenshots may use `github.com/user-attachments` URLs from an issue or PR upload instead of committed binaries.
