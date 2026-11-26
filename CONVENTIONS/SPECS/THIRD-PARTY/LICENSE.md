---
id: conventions.specs.third-party.license
---
# License file
> Load when: adding or changing a project's license file, or writing license fields in manifests.

- Which license: `CONVENTIONS/GITHUB/REPO/METADATA.md`.
- File `LICENSE` at the root, no extension; full unmodified text (<https://choosealicense.com/licenses/mit/>) so GitHub detects it.
- Copyright line: `Copyright (c) <year> <holder>`; year of first publication, holder = the publishing org or author.
- Manifests use the SPDX id: `PKGBUILD` `license=('MIT')`, `flake.nix` `meta.license = lib.licenses.mit`, `package.json` `"license": "MIT"`, `SKILL.md` `license: MIT`.
- Packages install the file (`CONVENTIONS/PACKAGING/ARCH.md`).
- Forks keep the upstream license and copyright line; add yours below it.
