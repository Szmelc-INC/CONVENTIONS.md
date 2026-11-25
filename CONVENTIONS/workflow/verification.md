# Verification
> Load when: any code change.

- Prove it works with the cheapest real check: build, run, hit the path.
- Run existing tests covering touched code; full suite only for cross-cutting changes.
- New tests only for: non-trivial logic, regressions, parsers, security boundaries, public APIs.
- Never: tests for glue/getters/one-off scripts, tests of tests, mocks of mocks, tests that re-assert the implementation.
- Tests and experiments use throwaway state (temp `HOME`, config dir, DB, `GNUPGHOME`); never the real config, data or keys.
- Shell: `bash -n`/`sh -n` and `shellcheck` before delivery (`CONVENTIONS/code/shell.md`).
- Never claim "works" unchecked. Unverifiable → say so.
