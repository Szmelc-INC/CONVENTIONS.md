# Repo metadata
> Load when: creating a repo, first push, release, or editing README/manifest/license.

- `gh repo view` first; fill gaps via `gh repo edit`: description, homepage, topics, badges.
- Homepage priority: real site → GitHub Pages → repo URL. Never invent.
- Keep manifest fields (package.json, go.mod, PKGBUILD, flake.nix…) in sync with repo metadata.
- License: MIT.
- Fork of someone else's project: say "independent, not affiliated" in the README and the description; add a trademark note when the upstream name is a mark.
