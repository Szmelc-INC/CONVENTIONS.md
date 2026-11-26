---
id: conventions.experimental.spec-files
---
# Spec file taxonomy
> Load when: user opts into experimental conventions, or designs Szmelc™ spec files (SZMELC.md, KOMBINAT.md, TEAM.md, MODULE.md, ASSERTIONS.md, POLICY.md, MEMORY.md).

Proposal from draft v2 (Kombinat). None of these files exist yet; adopt one only together with a parser or check that reads it.

| File | Role | Mandatory sections |
|---|---|---|
| `SZMELC.md` | Root axioms: anti-bloat, portability order Arch > Nix > WSL > macOS, Go + PHP stack | Philosophy, Stack Invariants, Portability Rules |
| `KOMBINAT.md` | System topology: backbone API, lifecycle, CI/CD, run modes (System, Sandbox, Portable) | Backbone API, Lifecycle, Execution Modes |
| `TEAM.md` | Operators, roles, access, co-op routing (Discord IDs, GitHub handles) | Roles, Permissions, Co-Op Routing |
| `MODULE.md` | Plugin blueprint: code, config schema, UI bindings, agent setup prompt | Manifest, Config Schema, Agent Setup Guide |
| `ASSERTIONS.md` | Deterministic invariants checked before any state mutation | Pre-Conditions, Invariants, Fallback Actions |
| `POLICY.md` | Risk levels, capability sandboxing, human approval gates | Risk Levels, Capability Matrix, Audit Triggers |
| `MEMORY.md` | Persistence: storage tiers, retention, indexing | Storage Tiers, Retention Policy, Indexing Rules |

- Already covered by stable formats: `AGENTS.md`/`CLAUDE.md` (`CONVENTIONS/SPECS/THIRD-PARTY/AGENTS-MD.md`), `SKILL.md` (`CONVENTIONS/SPECS/THIRD-PARTY/SKILL-MD.md`).
- Every spec file: rigid heading hierarchy + YAML/TOML frontmatter so LLMs and Go/PHP parsers extract the same structure.
