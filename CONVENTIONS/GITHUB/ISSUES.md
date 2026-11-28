---
id: conventions.github.issues
---
# Issues
> Load when: creating, triaging or closing issues, or adding issue templates.

- Issue forms: `.github/ISSUE_TEMPLATE/<name>.yml` with `labels:` preset; org default in the org `.github` repo (`CONVENTIONS/GITHUB/ORGANIZATIONS.md`).

| Form | File | Preset labels |
|---|---|---|
| Rule bug | `.github/ISSUE_TEMPLATE/rule-bug.yml` | `bug` |
| Rule proposal | `.github/ISSUE_TEMPLATE/rule-proposal.yml` | `feat` |
| Tooling bug | `.github/ISSUE_TEMPLATE/tooling-bug.yml` | `bug`, `area/meta` |
| Profile request | `.github/ISSUE_TEMPLATE/profile-request.yml` | `feat`, `area/agents` |
| Pack proposal | `.github/ISSUE_TEMPLATE/pack-proposal.yml` | `feat`, `needs-triage` |
| Adapter request | `.github/ISSUE_TEMPLATE/adapter-request.yml` | `feat`, `needs-triage` |
| Spec RFC | `.github/ISSUE_TEMPLATE/spec-rfc.yml` | `feat`, `needs-triage` |
- `.github/ISSUE_TEMPLATE/config.yml`: `blank_issues_enabled: false`; `contact_links` to Discussions, docs or support.
- Title: imperative, specific, no type prefix (`Fix crash on empty config`, `Add --json to list`); type goes in the label.
- Label on creation (`CONVENTIONS/GITHUB/REPO/LABELS.md`); set the issue type when the org defines types (`--type Bug`).
- Split work into sub-issues (`gh issue create --parent <n>`, `gh issue edit <n> --add-sub-issue <m>`); short checklists stay `- [ ]` task lists.
- Dependencies: `--blocked-by <n>` / `--blocking <n>`, not prose.
- Close via the PR: `Closes #<n>` in the PR body; keywords only fire when the PR targets the default branch.
- Closing without a PR: comment why, close as not planned or duplicate (`gh issue close <n> -r "not planned" -c "<why>"`).
- Roadmap: one issue with sub-issues, pinned (`gh issue pin <n>`); max 3 pinned.
- Agents: `gh issue list/view/create/edit/comment` with `--json`; never close an issue you did not resolve.
