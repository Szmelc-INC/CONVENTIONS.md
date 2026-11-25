# Design docs & agent briefs
> Load when: starting a project, writing a brief for a coding agent, or changing a project's architecture.

| File | Written by | Job |
|---|---|---|
| `DESIGN.md` | Owner, own words | Raw intent: what, for whom, why; constraints; nice-to-haves marked as such. Agents never rewrite it. |
| `docs/ARCHITECTURE-v<N>.md` | Agent + owner | Binding contract for major version N: paths, config, CLI, storage, tests. |
| `docs/<NAME>-SPEC.md` | Agent + owner | Contract between a runtime and its extensions (addons, plugins, drivers). |
| `<SOURCE>.md` | Human | External source document an implementation follows. |

- Read `DESIGN.md` and the current architecture contract before changing anything.
- A change that deviates from the contract updates the contract in the same commit.
- Briefs: ordered phases, each with a literal acceptance criterion; a phase starts only when the previous one passes; report after each.
- Build a thin working vertical slice first, never broad stubs.
- List fixed tech decisions with a one-line reason each, and one anchor example (config, CLI session) the implementation must match.
- Ambiguity → the simplest option that satisfies the brief, assumption stated inline, keep going.
- "Reproducible" means repeatable from the same inputs unless bit-for-bit is stated.
