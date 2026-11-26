---
id: conventions.github.releases.automation
---
# Release automation
> Load when: writing or running a release workflow or script, attaching release assets, or bumping downstream packages.

- Default: a human pushes the tag (`CONVENTIONS/GITHUB/RELEASES/TAGS.md`); `.github/workflows/release.yml` does the rest.
- Trigger `on: push: tags: ['v*']`, plus `workflow_dispatch` with a tag input for reruns.
- A tag pushed by a workflow with `GITHUB_TOKEN` triggers nothing; dispatch the release instead (`CONVENTIONS/GITHUB/ACTIONS/WORKFLOWS.md`).
- `contents: write` on the release job only.
- Build every asset on CI from the tag; never upload local builds.
- Attach assets + `SHA256SUMS` (`sha256sum <assets> > SHA256SUMS`), plus a signature (`SHA256SUMS.sig`) when the project signs.
- Publish: `gh release create "$TAG" --verify-tag --notes-from-tag <assets>`; no curated notes → `--generate-notes`; `-rc.N` → add `--prerelease`.
- `.github/release.yml` groups generated notes by label (`CONVENTIONS/GITHUB/REPO/LABELS.md`): `changelog.categories` for `feat`, `bug`, `docs`, `chore`, last one `"*"`.
- Release logic is a repo script that runs locally with `--dry-run`: builds, checksums, prints the `gh` commands without publishing.
- Downstream bumps after publish: package metadata and `flake.nix` via PR, or `repository_dispatch` to the packaging repo.
- Verify: `gh release view "$TAG"` lists every asset, checksums match, downstream PRs green.
- Release-please style automation only when the project uses Conventional Commits strictly (`CONVENTIONS/WORKFLOW/COMMITS.md`).
