---
id: conventions.repo.docs
---
# Docs structure
> Load when: writing or restructuring a README, guide or docs page, or filling the body of one of its sections.

Section order: `CONVENTIONS/SPECS/THIRD-PARTY/README-MD.md`. Voice: `CONVENTIONS/REPO/WRITING.md`. Voice profile and examples: `AGENTS/PROMPT/DOCS-VOICE.md`. Skeleton: `TEMPLATES/project-README.md`.

- Open: `# Name`, one bold sentence that says what it is and for whom, one plain sentence that says what the reader gets. Facts only: count, scope, platform.
- More than one guide → a "Start here" table first: guide, what it covers, when to read it. Mark the one to read first.
- Topic map: two-column table `Topic | What you learn`, one row per topic, ≤ 8 rows.
- What's inside: annotated tree in a `text` block; one entry per line, comments aligned in one column, ≤ 2 levels unless the third level teaches something.
- Install: `Option 1` (recommended) before `Option 2` (manual). Each option is one fenced block with a `#` comment above every command, then one line that says what the reader now has.
- Precedence or lookup order: numbered list, highest first, each line `` `source` `` then its effect.
- Key concepts: one `###` per concept, one sentence that defines it, then the smallest real example (front matter, a five-line file, one command).
- Limits as numbers: "keep under 10 enabled per project", never "too many". Put them in a notes section near the end.
- Customization: tell readers what to keep, change and remove; never imply that one setup fits all.
- Contributing: a short list of wanted contribution kinds, then the link to `CONTRIBUTING.md`.
- Horizontal rules (`---`) only between top-level sections of a README longer than ~150 lines.
- End with the license line. No star request, slogan or sign-off after it.
- Every command, path and count in the doc exists and is current; update it in the same change as the code.
