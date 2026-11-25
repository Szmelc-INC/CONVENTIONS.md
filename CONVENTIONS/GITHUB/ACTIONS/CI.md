# CI
> Load when: setting up or changing CI checks or required status checks, or fixing a red CI run.

- `.github/workflows/check.yml` runs on every push and PR, without a `paths:` filter.
- It runs format + lint, build, tests, package build, docs-in-sync; cheap steps first, fail fast, no `continue-on-error` on required steps.
- Lint per stack: `shellcheck` for shell, `go vet` + `gofmt -l` for Go, the ecosystem's standard linter elsewhere.
- Package build: `PKGBUILD` in an Arch container, `nix build` when a flake ships (`CONVENTIONS/PACKAGING/ARCH.md`, `CONVENTIONS/PACKAGING/NIX.md`).
- Docs-in-sync: regenerate generated files, `--help` output and completions, then `git diff --exit-code`.
- Tests run on throwaway state (temp `HOME`, temp dirs), never on real user config.
- Required checks (`CONVENTIONS/GITHUB/REPO/SETTINGS.md`) match job names: keep them stable; renaming a job blocks merges until the ruleset is updated.
- On failure, upload logs and test output: `actions/upload-artifact` with `if: failure()` and a short `retention-days`.
- CI never pushes to `main`. Exception: bots listed in one place (README "Automation" section), pushing via a ruleset bypass actor or a PR.
- Schedule heartbeat bot: commits one file (`.github/heartbeat`) only after ~45 quiet days, never daily.
- Red CI: read `gh run view <id> --log-failed`, reproduce with the local script, fix, push; never rerun until green.
