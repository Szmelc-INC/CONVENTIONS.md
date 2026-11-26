# Decision 0002: adopt the context-system proposal in slices

- Status: accepted
- Date: 2026-11-26
- Proposal: [`SPEC/proposals/0002-context-system.md`](../proposals/0002-context-system.md). It describes a rule corpus, a registry, a compiler and a workspace resolver.
- Decision: adopt the target architecture. Map each part onto the existing format, the Go CLI and the roadmap stages. Ship it as small pull requests, one slice each.
- Rationale: most of the proposal extends what the repository already has. A single large change would bypass review and conflict with the stage 3 Go port.
- Compatibility: no change to Format 1.0 or to `index.json` version 2 in this decision. New front matter keys arrive in a later minor format version.

## Reconciled points

The proposal was written without the current repository in view. These points replace the matching proposal text.

| Topic | Proposal | Decision |
|---|---|---|
| Rule metadata source | TOML shards in `META/compat/<topic>.toml` | Rule metadata stays in rule front matter (Format 1.0). `META/compat/registry.toml` stays the third-party compatibility registry. This keeps the proposal's own split between rule entries and adapter targets (section 2.2). |
| Registry shards | Split when the registry grows | Applies to `META/compat/` only. Split it when review or merge conflicts become a problem. The build merges shards in a stable order and rejects duplicate IDs. |
| Resolver command | `szmelc-resolve` shell wrapper | `conventions resolve [WORKSPACE] --paths\|--json\|--bundle` in the Go CLI. It extends `conventions match`. A neutral core does not ship profile-branded commands. |
| Build runtime | POSIX shell with a Python 3.11 helper | The Go port in `internal/build` replaces the shell build. `META/tools/build.sh` stays until the port reaches parity. |
| `detect` field | New registry field | Use the existing `scope` front matter globs and `glob()` trigger atoms. No second glob field. |
| `requires` and `links` | Registry fields | New optional front matter keys in a minor format version. `requires` is a directed acyclic graph. `links` is an undirected related-topic list. |
| `tier` (L0 to L5) | Required field | Optional key, used only by rules in the cybernetic model. It stays separate from `status` and from profile selection (section 20.9). |
| Lifecycle | `status` values `proposed` to `retired` | Keep the current `status` values (`stable`, `experimental`, `legacy`). Add optional provenance keys: `sources`, `version`, `verified_at`, `owner`. |
| Domain tree | About 50 fixed domain directories | Add a category only when it holds real rules. Do not create empty directories (section 20.2). Category names stay uppercase. |
| `SZMELC-AND-META/` domain | Core domain | Profile material lives in `PROFILES/` and `SZMELC/`, not in the neutral core. |
| Root `README.md` | Replace with the proposal | The root README describes the implemented state. The proposal stays in `SPEC/proposals/`. |
| Badges | Tool badges, one purple | Not adopted. Badge colors follow `CONVENTIONS/DESIGN/COLORS.md`. |

## Mapping to the repository

| Proposal section | Current state | Next slice | Stage |
|---|---|---|---|
| 2, 4: cores and layout | Done. Cores `CONVENTIONS/`, `AGENTS/`, `HUMANS/`, `CONTRIBUTING/`, `META/`, `TEMPLATES/` | None | #50 |
| 3.2: tiered loading | Done. `AGENTS.md`, `INDEX.md`, rule files | Per-category `INDEX.md` maps | #52 |
| 5: rule file format | Done. Format 1.0, `RULE-FILES.md` | Add `Verification` and `References` sections to `TEMPLATES/` | #51 |
| 5.4, 13.2: `requires` and `links` | Missing | Format 1.1 keys, schema, fixtures, cycle check in `conventions lint` | #52 |
| 6.3: lifecycle and provenance | Partial. `status`, `since`, `supersedes` | Format 1.1 provenance keys | #55 |
| 7.1: `index.json` | Done. Version 2 with schema | Carry the new keys and a generator version | #52 |
| 7.3: category indexes | Missing | Generated `CONVENTIONS/<CATEGORY>/INDEX.md` | #52 |
| 7.4: `COMPATIBILITY.md` | Done, generated from the registry | Separate `planned`, `generated` and `tested` adapter states | #53 |
| 8: workspace resolver | Partial. `conventions match <task> [paths]` | `conventions resolve` with ignore list, scan limit, prerequisite order and fixtures | #52 |
| 9: adapters | Partial. Copilot, Cursor and Kiro adapters, `SPEC/INTEROP.md` | Adapter target data file and per-adapter fixtures | #52, #58 |
| 10: agent protocols | Partial. `AGENTS/RULES/`, `SPECS/THIRD-PARTY/` | Rules per protocol, with version and source | #57 |
| 11: security and trust | Partial. Pinned actions, attestations, installer backups | Path traversal and hook checks in `conventions lint` | #53 |
| 12, 13: build and CI | Done in shell. Go port in progress | Orphan report, DAG check, resolver tests | #52, #53 |
| 14: installer and hooks | Partial. Installer with backup and uninstall | Opt-in session hooks with dry run and merge tests | #52, #58 |
| 15: L0 to L5 model | Missing | Experimental rules in `CONVENTIONS/EXPERIMENTAL/` first | #57 |
| 16, 17: topic catalogue | Discovery map only | Packs add rules on demand, each with a source and version | #57 |
| 19: versioning and governance | Done. SemVer, changelog, `SPEC/decisions/`, `CONTRIBUTING/DECISIONS.md` | External-source review cadence | #55 |
| 21: phases 1 to 6 | Phase 1 done. Phases 2 to 6 map to the slices above | None | #49 |

## Order of slices

1. Format 1.1 draft: `requires`, `links` and provenance keys, with schema and conformance fixtures.
2. `conventions lint`: dependency cycle, missing target and self-dependency checks.
3. `conventions resolve`: workspace scan, `--paths`, `--json`, `--bundle`, include and exclude overrides.
4. Generated per-category `INDEX.md` maps.
5. Adapter target data and opt-in session hooks.
6. Experimental L0 to L5 rules and the first catalogue packs.

Each slice is one pull request with its own tests. The tracking issue lists the slices and links each pull request.
