# Changelog
> Load when: creating or updating CHANGELOG.md, or preparing a release in a project that keeps one.

- Format: Keep a Changelog 1.1 <https://keepachangelog.com/en/1.1.0/>. File `CHANGELOG.md` at the root, when the project keeps one (`CONVENTIONS/GITHUB/RELEASES/VERSIONING.md`).
- Top: `# Changelog`, then `## [Unreleased]`, then releases newest first as `## [x.y.z] - YYYY-MM-DD`.
- Entries under `### Added`, `### Changed`, `### Deprecated`, `### Removed`, `### Fixed`, `### Security`; omit empty groups.
- One line per user-visible change, written for users; no commit hashes, no internal refactors.
- Add the entry under `[Unreleased]` in the same PR as the change.
- Release: rename `[Unreleased]` to the version and date, open a new empty `[Unreleased]`.
- Compare links at the bottom: `[Unreleased]: <repo>/compare/vX.Y.Z...HEAD`, `[x.y.z]: <repo>/compare/vPREV...vX.Y.Z`.
- The release section becomes the tag message and release notes (`CONVENTIONS/GITHUB/RELEASES/TAGS.md`).
