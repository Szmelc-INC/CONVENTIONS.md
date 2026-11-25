# Finish every change
> Load when: finishing a feature or fix, before calling work done.

- Done means everything the change touches is done; never leave half a feature for later.
- Carry it through the code, the `--help` text (global and per command) and the shell completions.
- Carry it through the docs (`README.md`, config comments) and packaging (`CONVENTIONS/packaging/arch.md`, `CONVENTIONS/packaging/nix.md`).
- Version bumps move together: the version constant, PKGBUILD `pkgver`, `flake.nix` `version`.
- Then verify on real data (`CONVENTIONS/workflow/verification.md`) and get green CI before reporting (`CONVENTIONS/workflow/git-pr-ci.md`).
