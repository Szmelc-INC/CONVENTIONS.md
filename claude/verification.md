# Verification
> Load when: any code change.

- Prove it works with the cheapest real check: build, run, hit the path.
- Run existing tests covering touched code; full suite only for cross-cutting changes.
- New tests only for: non-trivial logic, regressions, parsers, security boundaries, public APIs.
- Never: tests for glue/getters/one-off scripts, tests of tests, mocks of mocks, tests that re-assert the implementation.
- Never claim "works" unchecked. Unverifiable → say so.
