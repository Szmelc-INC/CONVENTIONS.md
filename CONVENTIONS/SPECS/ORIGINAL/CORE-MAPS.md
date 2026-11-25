# Core maps
> Load when: organising a doc tree into cores, adding a core or category, or editing a core README.

- Core = UPPERCASE directory `X/` + guide `X/README.md` + generated root map `X.md`.
- `X/README.md`: line 1 `# Title`, line 2 `> Load when: <trigger>`, then what the core holds and a table of its categories.
- Root map `X.md`: generated: title, trigger, link to the guide, then `| Path | What | Load when |` rows from each file's header. Never hand-edit.
- A hand-written root file keeps its map between `<!-- map:begin -->` and `<!-- map:end -->`; only that block is generated.
- Nested categories repeat the pattern; `X/<SUB>/README.md` is optional, only when a category needs more than its table row.
- Every category directory has a row in its core guide's table.
- Any project may adopt it for a doc tree; the build script generates maps and indexes (`CONVENTIONS/SPECS/ORIGINAL/INDEX-MD.md`).
- This repo: cores `CONVENTIONS/`, `AGENTS/`, `HUMANS/`, `CONTRIBUTING/`, `SZMELC/`, `META/`; root maps `CONVENTIONS.md` (bundle, opens with the map), `AGENTS.md` (map block), `HUMANS.md`, `CONTRIBUTING.md`, `SZMELC.md`, `META.md`.
