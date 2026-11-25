# Agent instruction files
> Load when: creating or editing AGENTS.md, CLAUDE.md, GEMINI.md, QWEN.md, Cursor/Copilot/Kiro/Windsurf rules, or llms.txt in any project.

- Canonical: `AGENTS.md` at the project root; add one per subdir only when a subtree has its own rules.
- `CLAUDE.md`, `GEMINI.md`, `QWEN.md`: a single line `@AGENTS.md` (import). Never duplicate content.
- Codex, Cursor, Copilot, OpenCode, Zed, Jules and Amp read `AGENTS.md` natively; add tool-specific files only when a tool needs frontmatter.
- Tool-specific files (`.cursor/rules/*.mdc`, `.github/instructions/*.instructions.md`, `.kiro/steering/*.md`): generate from a source, never hand-edit copies. `./install.sh project <dir>` drops the Szmelc ones.
- Content: only what an agent cannot infer — build/test/lint commands, layout map, project-specific rules, gotchas.
- Never restate global conventions; reference them by path in this repo (`interfaces/cli.md`).
- Imperative one-liners. Over ~150 lines → split per subdir.
- Docs site → also ship `llms.txt` (llmstxt.org): `# Name`, `> summary`, `##` link lists, `## Optional` for skippable links.
- Skeleton: `_template/AGENTS.md`. Skills: `meta/skills.md`.
