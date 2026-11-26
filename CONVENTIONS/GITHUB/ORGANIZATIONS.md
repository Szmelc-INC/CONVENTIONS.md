---
id: conventions.github.organizations
---
# Organizations
> Load when: creating or maintaining a GitHub organization, its profile, teams, or org-wide defaults.

- Org profile: public `.github` repo with `profile/README.md` (`CONVENTIONS/SPECS/THIRD-PARTY/README-MD.md`).
- Org `.github` repo holds default community health files, `.github/ISSUE_TEMPLATE/` and `.github/PULL_REQUEST_TEMPLATE.md`; repos override only when they differ.
- Access through teams with least privilege, never per-person grants on each repo.
- Pin up to 6 flagship repos on the org profile.
- Every repo: consistent name (`CONVENTIONS/CODE/NAMING.md`), description, homepage, topics (`CONVENTIONS/GITHUB/REPO/METADATA.md`).
- Same labels and settings everywhere (`CONVENTIONS/GITHUB/REPO/LABELS.md`, `CONVENTIONS/GITHUB/REPO/SETTINGS.md`).
- Cross-repo planning: org-level Projects (`CONVENTIONS/GITHUB/PROJECTS.md`).
- Org settings, membership and repo visibility: owner approval first.
