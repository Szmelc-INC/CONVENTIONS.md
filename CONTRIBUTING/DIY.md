# Conventions DIY
> Load when: building your own conventions repo (team, org, personal) on this skeleton, or layering one on top of Szmelc.

- Start from a fork (to keep syncing) or a fresh copy (to diverge); MIT, keep `LICENSE`.
- Keep the pipeline: `META/tools/build.sh`, `META/tools/check.sh`, `META/tools/site.sh`, `.github/workflows/`. Never hand-edit outputs (`CONTRIBUTING/INDEXING.md`).
- Keep the core pattern: directory + `X/README.md` + generated root map (`CONVENTIONS/SPECS/ORIGINAL/CORE-MAPS.md`).

## Rename (grep `szmelc-conventions`, `Szmelc-INC/CONVENTIONS.md`, `szmelc/conventions` and replace every hit)
- Meta skill: `name:` in `SKILL.md` and `check_skill SKILL.md <name>` in `META/tools/check.sh`.
- `RAW` URL, adapter file names and the llms.txt summary line in `META/tools/build.sh`.
- Install path and harness link names in `install.sh`, `META/tools/test-install.sh`, `TEMPLATES/AGENTS.md`.

## Add or remove a core
- Directory + `README.md` with header, then edit `CORES` in `META/tools/build.sh`, `META/tools/check.sh`, `META/tools/site.sh`.
- Also `MAPS` in `META/tools/build.sh` and the `sources=(...)` list in `META/tools/check.sh` rule 7.
- Category inside a core: directory + row in the core guide's table; no script change.

## Projects index and Pages
- List your owners in a `sources.conf` like `SZMELC/sources.conf`; point `META/tools/site.sh` at it.
- Enable Pages with source GitHub Actions (`CONVENTIONS/GITHUB/DEPLOYMENTS/GITHUB-PAGES.md`); set the repo homepage to the site.

## Layer on top of Szmelc
- Reference upstream rules by raw URL (`https://raw.githubusercontent.com/Szmelc-INC/CONVENTIONS.md/main/<path>`) or vendor it as a git submodule.
- Precedence: your local rules > upstream stable > upstream experimental. Say so in your `SKILL.md` "Use" section.
- Sync a fork: `git remote add upstream https://github.com/Szmelc-INC/CONVENTIONS.md`, then periodically `git fetch upstream && git merge upstream/main` on a `chore/*` branch; rebuild, check, PR.
