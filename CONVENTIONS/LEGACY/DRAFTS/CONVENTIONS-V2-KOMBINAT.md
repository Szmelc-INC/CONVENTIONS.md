# CONVENTIONS.md — The Absolute Specification (`v2.0` Kombinat / `v3.0` Logos)

> **Meta-Principle (Ontological & Epistemological Root):**  
> Everything is a self-describing, composable node. A system achieves **Emergent Complexity** only when its atomic units share an invariant schema. Every file, agent, plugin, and workflow is strictly deterministic at the boundary and infinitely modular within.

---

## I. Taxonomy of `*.md` Standard Formats

All system intelligence, configuration, and execution protocols are governed by declarative Markdown specifications paired with structured schemas (`JSON`/`TOML`).

### 1. Core Identity & Governance

| File | Scope & Ontological Role | Mandatory Sections |
| :--- | :--- | :--- |
| **`SZMELC.md`** | **Root Axioms.** Anti-bloat manifesto, Unix/POSIX portability rules (`Arch > Nix > WSL > macOS`), and core `Go` + `PHP` stack invariants. | `# Philosophy`, `# Stack Invariants`, `# Portability Rules` |
| **`KOMBINAT.md`** | **System Topology.** Defines the central API backbone, state lifecycle, CI/CD pipelines, and runtime execution modes (`System`, `Sandbox`, `Portable`). | `# Backbone API`, `# Lifecycle`, `# Execution Modes` |
| **`TEAM.md`** | **Organizational Graph.** Maps human operators, roles, access policies, and multiplayer co-op routing (`Discord IDs`, `GitHub` handles). | `# Roles (CEO/CTO/CDO)`, `# Permissions`, `# Co-Op Routing` |
| **`CONVENTIONS.md`** | **Meta-Schema.** The recursive ruleset governing naming, versioning (`SemVer`), directory trees, localization (`en` + `pl`), and file validation. | `# Naming & Versioning`, `# Localization`, `# Directory Tree` |

### 2. Agentic & Deterministic Execution

| File | Scope & Epistemological Role | Mandatory Sections |
| :--- | :--- | :--- |
| **`AGENTS.md`** | **Fleet Orchestration.** Universal directives for multi-agent collaboration, conflict-free parallel work, and token/allowance budgeting. | `# Fleet Routing`, `# Concurrency Locks`, `# Token Limits` |
| **`CLAUDE.md`** | **Runtime Context.** Model-specific system prompts, codebase maps, terminal execution rules, and git workflow automation. | `# Codebase Map`, `# Shell Rules`, `# Git Protocol` |
| **`SKILL.md`** | **Atomic Capabilities.** Self-contained tool definitions. Agents cannot execute actions outside registered `SKILL.md` manifests. | `# Trigger`, `# Input/Output Schema`, `# Execution Script` |
| **`ASSERTIONS.md`** | **Verification Layer.** Deterministic invariants (`Assertion-Driven Architecture`) that validate agent outputs before state mutation. | `# Pre-Conditions`, `# Invariants`, `# Fallback Actions` |

### 3. Ecosystem & Module Distribution (`KUR`)

| File | Scope & Methodological Role | Mandatory Sections |
| :--- | :--- | :--- |
| **`MODULE.md`** | **Plugin Blueprint.** Complete specification for `KUR` (Kombinat User Repositories) packages: code, configs, UI bindings, and setup prompts. | `# Manifest`, `# Config Schema`, `# Agent Setup Guide` |
| **`MEMORY.md`** | **Persistence & Logs.** Schema for `Memory 5` (Vector DB, RAG indices, audit journals, and cross-session user state). | `# Storage Tiers`, `# Retention Policy`, `# Indexing Rules` |
| **`POLICY.md`** | **Security & Guardrails.** Risk thresholds, capability sandboxing, and human-in-the-loop approval gates. | `# Risk Levels`, `# Capability Matrix`, `# Audit Triggers` |

---

## II. Architectural & Methodological Rules

### 1. Structural Invariants (The "100 Flavors" Rule)
* **Fractal Composability:** Every module MUST run identically in isolation (standalone CLI), in arbitrary combinations, or inside the full `Kombinat` mesh.
* **Zero-Hardcode Rule:** The core backbone contains *only* the central API router, state machine, and module loader. Everything else (`UI`, `Discord Bot`, `Locales`, `Fleet`) is a toggleable plugin.
* **Declarative State:** All runtime behavior is exposed via `config.toml` or `config.json`. No hidden state.

### 2. Agentic Collaboration Protocol (`AGENTS.md` Standard)
1. **Read Before Write:** Agents must parse `CONVENTIONS.md` and local `MODULE.md` before modifying any file.
2. **Assertion Gating:** Every agent task passes through deterministic `ASSERTIONS.md` checks before committing to the `Tasks` queue.
3. **Capability Least-Privilege:** An agent only sees and invokes tools explicitly declared in its active `SKILL.md` scope.
4. **Verbose Observability:** All prompts, tool calls, token metrics, and state transitions stream in real time to the `Live Terminal` and `Memory 5`.

### 3. Localization & Dual-Language Standard (`en` + `pl`)
* **`[EN]` Primary (Structural):** All source code, identifiers, schemas, comments, and technical specs are strictly English.
* **`[PL]` Secondary (Conversational/Native):** User-facing strings, CLI/TUI/WebUI labels, and Discord embeds map dynamically via `translate-shell` locale packs without altering core logic.

### 4. Szmelc™ Versioning & Evolution (`v1` \(\rightarrow\) `v2` \(\rightarrow\) `v3`)
* **`v1` (`Legacy`):** Monolithic, chaotic prototypes. Source material for extraction.
* **`v2` (`Kombinat`):** Standardized, modular, API-centric refactoring via CI/CD.
* **`v3` (`Logos`):** The absolute convergence—self-assembling, fully fuzz-tested, universal meta-system where specification *is* execution.

---

## III. Canonical Module Directory Skeleton

Every `KUR` module repository must strictly adhere to this tree:

```text
<module-name>/
├── MODULE.md          # Complete documentation, schema & agent setup prompts
├── SKILL.md           # Agent-callable capability definitions
├── ASSERTIONS.md      # Deterministic validation rules
├── config.default.toml # Exhaustive default configuration
├── src/               # Core logic (Go / PHP / POSIX Shell)
├── ui/                # Modular WebUI / TUI / Discord component bindings
└── locales/           # Native translation packs (en.json, pl.json)
```
