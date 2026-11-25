# Working on this repo
- Follow "Rules of this repo" in `README.md`.
- Edit sources only: rule files, `global/AGENTS.md`, `SKILL.md`, `skills/`, `_template/`, `tools/`, `install.sh`.
- Never hand-edit generated files: `INDEX.md`, `index.json`, `llms.txt`, `CONVENTIONS.md`, `adapters/`. Run `tools/build.sh`.
- After any change: `tools/build.sh && tools/check.sh`; both must pass. Installer change → also `tools/test-install.sh`.
- Branch lanes: `workflow/branches.md`. PRs target `main` from `testing`, `experimental` or `legacy`.
- Keep files terse: imperative one-liners, no prose. Every word here costs tokens in every session that loads it.
