# Releases & versioning
> Load when: bumping a version, tagging a release, or planning a major version.

- SemVer `vMAJOR.MINOR.PATCH`; tag on `main` only.
- The version lives in package metadata and tags; never in the README title or repo name.
- One bump moves every copy at once: source constant, PKGBUILD `pkgver`, `flake.nix` `version`, changelog if the project keeps one.
- Breaking change to a command, flag, config key or file format → major bump, plus a new `docs/ARCHITECTURE-v<N>.md` when the project keeps one.
- Ecosystem eras (`SZMELC/README.md`) are independent of project versions.
- Before tagging: versions agree; `--help`, completions and README match the code; tests pass on throwaway state; the package builds in CI; the architecture contract is current.
