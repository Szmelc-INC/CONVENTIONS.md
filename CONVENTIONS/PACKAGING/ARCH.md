# Arch packaging
> Load when: packaging, releasing, or adding install instructions.

- Ship a `PKGBUILD` (repo root or a packaging subdirectory) that installs: binary, shell completions, license, docs.
- SAUR builds every PKGBUILD in the org: the default branch publishes to `[saur]`; any other branch to `[saur-ex]` as `<name>-ex`, installable next to stable.
- Override per PKGBUILD: `_saur_channel=stable|experimental|skip`.
- VCS packages: `pkgver()` yielding `r<count>.<hash>`.
- Packages, databases and install scripts are signed; clients use `SigLevel = Required`.
- Version moves with the release (`CONVENTIONS/GITHUB/RELEASES/VERSIONING.md`).
- Nix counterpart: `CONVENTIONS/PACKAGING/NIX.md`. Installers: `CONVENTIONS/PACKAGING/INSTALL.md`.
