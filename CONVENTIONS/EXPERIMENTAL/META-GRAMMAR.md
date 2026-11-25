# Meta-grammar ("LEGO everything")
> Load when: user opts into experimental conventions, or designs tooling that parses, lints or generates from these conventions.

Proposal from draft v3. `CONVENTIONS.md` is the stud geometry, every `SKILL.md` is a brick.

| Layer | Artifacts | Role | Produced by |
|---|---|---|---|
| 0 Meta-law | `CONVENTIONS.md` | Parser contract: schemas, naming, versioning, file topology | Humans |
| 1 Governance | `SZMELC.md`, `KOMBINAT.md`, `TEAM.md` | Domain axioms | Derived from 0 |
| 2 Agent runtime | `AGENTS.md`, `CLAUDE.md`, `ASSERTIONS.md` | Guardrails, context, verification loops (`ada-agent`) | Compiled from 0–1 |
| 3 Atomic tools | `SKILL.md`, `MODULE.md` | Executable bricks | Generated from 0–2 |
| 4 Distribution | SAUR `[saur]` / `[saur-ex]` | Signed Arch/POSIX packages from git | CI/CD |

- Zero ambiguity: every spec has rigid headings + frontmatter; a parser and an LLM must extract the same tree.
- Generative derivation: a repo that follows the conventions gets its `SKILL.md`, `ASSERTIONS.md` suites and `PKGBUILD` generated, never hand-guessed.
- Primitives as bricks: `ada-agent` (assertion loop), `wrapi` (local OpenAI-compatible endpoint), `ultui` (JSON → TUI), `tesserae` (dashboard), `localui` (JSON → WebUI), `silkrouter` (proxy mesh), `cr0` (scheduler), SAUR (signed delivery).
- Dual channel: default branch ships `[saur]` stable; `-ex` suffix builds ship `[saur-ex]` (matches `CONVENTIONS/WORKFLOW/BRANCHES.md`).
- First step toward this already exists: `META/tools/build.sh` derives `INDEX.md`, `index.json`, `llms.txt` and adapters from headers.
