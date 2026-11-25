# Skills (SKILL.md)
> Load when: writing, editing, or installing an agent skill.

- Layout: `<name>/SKILL.md` + optional `scripts/`, `references/`, `assets/`. Directory name == `name`.
- Frontmatter: `name` (lowercase letters, digits, hyphens, ≤ 64), `description` (≤ 1024: what it does + when to use, with trigger words). Optional: `license`, `compatibility`, `metadata` (string map), `allowed-tools`.
- Body < ~500 lines. Push detail into `references/` and link it relatively (progressive disclosure).
- One capability per skill. Deterministic steps go in `scripts/`, not prose.
- Install by symlinking the directory into each harness skill root (`./install.sh` knows them). Never copy.
- Skeleton: `META/templates/SKILL.md`. Validate with `META/tools/check.sh` rules: name/dir match, description length.
