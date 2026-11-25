# Versioning & generations
> Load when: user opts into experimental conventions, or tags releases / plans a major rewrite.

Proposal from draft v2.

- Releases: SemVer `vMAJOR.MINOR.PATCH`; tag on `main` only.
- Generations of a project:
  - `v1` Legacy: monolithic prototypes; source material for extraction. Lives on the `legacy` lane.
  - `v2` Kombinat: modular, API-centric, CI/CD-built.
  - `v3` Logos: self-assembling, fuzz-tested; spec is execution.
- A new generation starts on `experimental`, is promoted via `testing`, and the previous one moves to `legacy`.
