---
id: conventions.specs.original.rule-files
---
# Rule files
> Load when: writing, naming or reviewing a convention rule file.

- Optional YAML front matter precedes the content; every stable and experimental rule has a unique, path-independent `id` there. The first content line is `# Title`, followed immediately by `> Load when: <concrete trigger>`; generators read both (`CONVENTIONS/SPECS/ORIGINAL/INDEX-MD.md`). Skeleton `TEMPLATES/rule.md`.
- Optional front matter `locales: <lang>=<path> ...` names companions written natively in other languages (BCP 47 primary tag, e.g. `pl`). The English file stays canonical. Companions live outside the rule tree (e.g. a skill `references/` dir), never enter the bundle, and the site offers a language toggle.
- One topic per file, one rule per line: imperative one-liners (`- ...`); a table only when denser than lines.
- ~5–20 lines; longer → split the topic.
- No prose, no filler adjectives; rationale only when the rule is non-obvious.
- Paths: categories and topic files UPPERCASE kebab (`CONVENTIONS/GITHUB/RELEASES/VERSIONING.md`).
- A rule about a named file `X.ext` is `X-EXT.md` (`AGENTS-MD.md`, `LLMS-TXT.md`), so harnesses and GitHub never mistake it for the file itself.
- Never duplicate a rule: reference the owning file by backticked repo path; every backticked path must exist.
- Status by directory, not by field: `EXPERIMENTAL/` opt-in, `LEGACY/` archive (line 3 `> Superseded by: <path>`), else stable; stable rules never reference either.
- State rules generically; project specifics go in that project's README or `AGENTS.md`.
