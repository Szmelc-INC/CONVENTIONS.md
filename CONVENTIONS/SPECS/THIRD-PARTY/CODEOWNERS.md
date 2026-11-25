# Code owners
> Load when: adding or editing CODEOWNERS, or requiring owner review on pull requests.

- File `.github/CODEOWNERS` <https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners>; GitHub also reads root and `docs/`, keep one.
- Only with ≥ 2 maintainers or when a ruleset requires code-owner review; solo repos skip it.
- Line: gitignore-style pattern, then owners; the last matching line wins.
- `*` default line first, narrower paths below it.
- Owners: teams (`@org/team`) over people; every owner needs write access.
- Required owner review: ruleset `pull_request` with `require_code_owner_review: true` (`CONVENTIONS/GITHUB/REPO/SETTINGS.md`).
