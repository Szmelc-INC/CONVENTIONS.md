---
id: contributing.diy
---
# Conventions DIY
> Load when: building your own conventions repo (team, organization or personal) on this skeleton.

- Start from a fork (to keep syncing) or a fresh copy (to diverge); MIT, keep `LICENSE`.
- Keep the pipeline: `META/tools/build.sh`, `META/tools/check.sh`, `META/tools/site.sh`, `.github/workflows/`. Never hand-edit outputs (`CONTRIBUTING/INDEXING.md`).
- Keep the core pattern: directory + `X/README.md` + generated root map (`CONVENTIONS/SPECS/ORIGINAL/CORE-MAPS.md`).

## Customize identity
- Meta skill: `name:` in `SKILL.md` and `check_skill SKILL.md <name>` in `META/tools/check.sh`.
- Set profile values for repository and site URLs, install path, skill name and organization identity.
- Keep generated adapters and indexes profile-aware; do not hard-code project identity in build scripts.
- Install path and harness link names belong in the profile and installer configuration.

## Add or remove a core
- Directory + `README.md` with header, then edit `CORES` in `META/tools/build.sh`, `META/tools/check.sh`, `META/tools/site.sh`.
- Also `MAPS` in `META/tools/build.sh` and the `sources=(...)` list in `META/tools/check.sh` rule 7.
- Category inside a core: directory + row in the core guide's table; no script change.

## Projects index and Pages
- List public projects in a profile-owned `sources.conf`; point `META/tools/site.sh` at that file.
- Enable Pages with source GitHub Actions (`CONVENTIONS/GITHUB/DEPLOYMENTS/GITHUB-PAGES.md`); set the repo homepage to the site.

## Upstream
- Reference upstream rules by raw URL or vendor them as a git submodule.
- Precedence: local rules > upstream stable > upstream experimental. State this in `SKILL.md`.
- Sync a fork by merging upstream `main` into a `chore/*` branch; rebuild, check and open a PR.
