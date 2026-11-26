---
id: contributing.indexing
---
# Indexing and formats
> Load when: adding or changing a rule file and wondering what to rebuild, or adding a new generated output format.

- One source, every format: each file's line 1 title and line 2 trigger feed every output (`CONVENTIONS/SPECS/ORIGINAL/INDEX-MD.md`). Pipeline overview: `META/README.md`.

| Output | Built by | For |
|---|---|---|
| `INDEX.md`, `index.json` | `META/tools/build.sh` | Agents (lazy load), tools |
| `llms.txt` | `META/tools/build.sh` | LLM web index |
| `CONVENTIONS.md` | `META/tools/build.sh` | All stable rules in one file |
| Core root maps and the `AGENTS.md` map block | `META/tools/build.sh` | Core maps |
| `COMPATIBILITY.md`, `index.json` `compatible` | `META/tools/build.sh` from `META/compat/registry.toml` | Compatible third-party formats and tools (`META/README.md`) |
| `AGENTS/adapters/` | `META/tools/build.sh` | Cursor, Copilot, Kiro |
| Site (`public/`, not committed) | `META/tools/site.sh` | GitHub Pages |

- After any source change: run `META/tools/build.sh && META/tools/check.sh` and commit the regenerated files with the source.
- CI never regenerates: it runs `META/tools/build.sh --check` and fails on stale output.
- The site rebuilds in CI on push to `main` touching Markdown, `META/tools/site.sh`, `META/compat/` or the selected profile's project-source file, nightly, and on manual or `repository_dispatch` trigger.
- Never hand-edit generated files; edit the source and rebuild.

## Add an output format
1. One generator block in `META/tools/build.sh` ending in `| emit <file>`.
2. Add the file to `GENERATED` there; `META/tools/check.sh` rule 1 then catches staleness.
3. Add it to the never-edit lists in root `AGENTS.md` (above the map block) and the `README.md` layout.
4. Minor bump (`CONTRIBUTING/VERSIONING.md`).
