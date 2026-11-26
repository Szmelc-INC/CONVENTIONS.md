# FAQ

## How does this relate to AGENTS.md and Agent Skills?

Conventions defines portable rule sources, stable IDs, triggers, and an index. AGENTS.md and Agent Skills are host formats. An adapter compiles a Conventions collection into those formats. It complements them and does not replace their host-specific behavior.

## Does every host support lazy loading?

No. A host may support glob selection, model-selected rules, explicit Skills, or only always-on files. The interop matrix records those limits. An adapter must not claim a lazy behavior the host does not provide.

## Is a profile a different format version?

No. A profile supplies project-specific names, links, colors, and other presentation values. It does not alter rule identity or format semantics.
