---
id: conventions.packaging.arch
---
# Arch packaging
> Load when: packaging, releasing, or adding install instructions.

- Ship a `PKGBUILD` (repo root or a packaging subdirectory) that installs: binary, shell completions, license, docs.
- `{{profile.package_registry}}` builds every PKGBUILD in the project; stable and experimental channels follow the registry's policy.
- Override the package channel with the registry's documented setting.
- VCS packages: `pkgver()` yielding `r<count>.<hash>`.
- Packages, databases and install scripts are signed; clients use `SigLevel = Required`.
- Version moves with the release (`CONVENTIONS/GITHUB/RELEASES/VERSIONING.md`).
- Nix counterpart: `CONVENTIONS/PACKAGING/NIX.md`. Installers: `CONVENTIONS/PACKAGING/INSTALL.md`.
