# CONVENTIONS.md — The Meta-Grammar & "Universal LEGO" Specification (`v2.0` -> `v3.0`)

> **Epistemological & Ontological Premise:**  
> A `SKILL.md` is a single brick; **`CONVENTIONS.md` is the stud-and-tube geometry that makes every brick click together.**  
> Instead of isolated tools or ad-hoc prompts, the entire ecosystem (`SAUR` packages, `Go`/`PHP` binaries, `JSON`/`TOML` configs, and AI agents) shares one deterministic, machine-parsable grammar. Everything connects at the parser level.

---

## I. The Hierarchy of Specification (From Meta-Law to Execution)

To resolve the tension between *"just write a skill"* and *"solve conventions globally"*, the architecture separates **Law** (universal schemas) from **Manifestation** (generated skills, docs, and packages):

| Layer | Artifact | Ontological Role | Generation Direction |
| :--- | :--- | :--- | :--- |
| **0. Meta-Law** | `CONVENTIONS.md` | **The Parser Contract.** Defines universal AST/schema rules, naming, versioning, and file topology across all `Szmelc-INC` repos. | **Root Source of Truth** (Human + Architect) |
| **1. Governance** | `SZMELC.md`, `KOMBINAT.md`, `TEAM.md` | **Domain Axioms.** Anti-bloat constraints, central API rules, and operator roles (`Sernik`, `Polski Kotek`, `Henderson`). | Derived from Layer 0 |
| **2. Agent Runtime** | `AGENTS.md`, `CLAUDE.md`, `ASSERTIONS.md` | **Cognitive Guardrails.** Fleet orchestration, context injection, and deterministic verification loops (`ada-agent`). | Compiled from Layers 0–1 |
| **3. Atomic Tools** | `SKILL.md`, `MODULE.md` | **Executable Bricks.** Single-purpose AI capabilities and `KUR` plugins packaged for immediate agent consumption. | **Auto-generated** from Layers 0–2 |
| **4. Distribution** | `SAUR` (`[saur]` / `[saur-ex]`) | **Binary & Package Delivery.** Signed, auto-rebuilt Arch/POSIX packages (`ultui`, `localui`, `wrapi`, `silkrouter`) shipped directly from Git. | Built automatically via CI/CD |

---

## II. The "LEGO Everything"™ Parser-Level Invariants

For every tool, UI, and agent to interoperate without glue code, all artifacts must obey four deterministic laws:

### 1. Deterministic Parsability (Zero-Ambiguity Rule)

* **Strict Frontmatter & Headers:** Every `*.md` specification uses rigid Markdown heading hierarchies and `YAML`/`TOML` frontmatter so both LLMs and `Go`/`PHP` parsers extract identical structures.
* **Config-Driven Rendering:** Interfaces are never hardcoded. One declarative `JSON`/`TOML` schema drives CLI flags, TUI canvases (`ultui`, `tesserae`), and WebUIs (`localui`) simultaneously.

### 2. Generative Derivation (`Conventions` → `Skills`)

* Agents do not manually guess how to build or use a repo.
* Because every repository follows `CONVENTIONS.md`, a meta-parser automatically synthesizes:
  1. Valid **`SKILL.md`** manifests for LLM tool-use.
  2. **`ASSERTIONS.md`** test suites for `ada-agent` loops.
  3. **`PKGBUILD`** & signed **`SAUR`** releases (`stable` vs `-ex` experimental branches).

### 3. Unified Stack & Ecosystem Synergy
Existing `Szmelc-INC` primitives serve as the physical bricks of this grammar:

* **Orchestration & Agents:** `ada-agent` (assertion loop) + `wrapi` (local OpenAI-compatible AI endpoint).
* **Interfaces:** `ultui` (JSON-to-TUI), `tesserae` (live dashboard), `localui` (JSON-to-WebUI).
* **Infrastructure:** `silkrouter` (proxy mesh), `cr0` (stateful scheduler), `SAUR` (automated signed delivery).

### 4. Dual-Channel Lifecycle (`stable` vs `ex`)

* **Default Branch (`[saur]`):** Production-grade, assertion-verified modules adhering strictly to `v2.0` conventions.
* **Feature Branches (`[saur-ex]`):** Parallel experimental builds (`-ex` suffix) allowing conflict-free R&D across humans and agents on the same host.

---

## III. Canonical `CONVENTIONS.md` Repository Blueprint

The central repository (`Szmelc-INC/CONVENTIONS.md`) acts as the **Command Center** imported by all child projects:

```text
CONVENTIONS.md/
├── README.md              # Human + LLM entry point & quick-reference index
├── schema/                # Machine-parsable JSON/TOML validators for all *.md types
│   ├── skill.schema.json
│   ├── module.schema.json
│   └── assertion.schema.json
├── templates/             # Canonical skeletons (SKILL.md, AGENTS.md, PKGBUILD)
├── generators/            # Go/Shell CLI tools to lint repos & auto-compile SKILL.md
└── specs/                 # Modular sub-conventions (git, versioning, locales, UI-JSON)
```
