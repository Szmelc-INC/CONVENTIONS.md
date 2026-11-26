---
id: conventions.specs.third-party.agents-md
---
# Agent instruction files
> Load when: creating or editing AGENTS.md, CLAUDE.md, GEMINI.md, QWEN.md, or Cursor/Copilot/Kiro/Windsurf rules in any project.

- Standard: <https://agents.md/>. Canonical `AGENTS.md` at the project root; add one per subdir only when a subtree has its own rules.
- `CLAUDE.md`, `GEMINI.md`, `QWEN.md`: a single line `@AGENTS.md` (import). Never duplicate content.
- Codex, Cursor, Copilot, OpenCode, Zed, Jules and Amp read `AGENTS.md` natively; add tool-specific files only when a tool needs frontmatter.
- Tool-specific files (`.cursor/rules/*.mdc`, `.github/instructions/*.instructions.md`, `.kiro/steering/*.md`): generate from a source, never hand-edit copies. The installer writes the selected profile's rules.
- Never keep two diverging copies (e.g. `CLAUDE.md` with the tool name swapped); one source, imports elsewhere.
- Content: only what an agent cannot infer — build/test/lint commands, layout map, project-specific rules, gotchas.
- Never restate global conventions; reference them by path in this repo (`CONVENTIONS/INTERFACES/CLI.md`).
- Project baseline: read `DESIGN.md` and the current architecture contract first; finish every change; tests on throwaway state; a deviation updates the contract in the same commit (`CONVENTIONS/SPECS/ORIGINAL/DESIGN-MD.md`).
- Imperative one-liners. Over ~150 lines → split per subdir.
- Skeleton: `TEMPLATES/AGENTS.md`. Related: `CONVENTIONS/SPECS/THIRD-PARTY/SKILL-MD.md`, `CONVENTIONS/SPECS/THIRD-PARTY/MCP-JSON.md`, `CONVENTIONS/SPECS/THIRD-PARTY/LLMS-TXT.md`.
