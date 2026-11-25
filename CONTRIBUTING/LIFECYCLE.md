# Rule lifecycle
> Load when: proposing, promoting, demoting or deprecating a convention, or tracking how a rule changed.

| Stage | How | Branch |
|---|---|---|
| Idea | Issue or discussion with the problem and a draft one-liner | none |
| Propose | New file in `CONVENTIONS/EXPERIMENTAL/`; agents load it only on opt-in | `experimental/*` |
| Promote | Move into its category, edit to stable wording, drop experimental references | `feat/*` |
| Change | Edit in place; wording-only fixes too | `feat/*` `fix/*` `docs/*` |
| Demote | Move to `CONVENTIONS/LEGACY/` with line 3 `> Superseded by: <path>` | `legacy/*` |
| Delete | Never: legacy is the archive; a wrong fact is fixed, not erased | none |

- Branch mechanics, scope and merge: `CONVENTIONS/WORKFLOW/BRANCHES.md`.
- Unverified or private drafts stay on `local/*` until reviewed.
- Renaming or moving a stable rule breaks references and pins: grep every backticked path, rebuild, and treat it as major (`CONTRIBUTING/VERSIONING.md`).
- Every lifecycle step is its own PR; the squash commit subject names the rule path.

## How users' agents notice changes
- Installs track `main`: `git -C ~/.config/szmelc/conventions pull`; agents re-read `INDEX.md` next session.
- What changed: `git -C ~/.config/szmelc/conventions log --oneline -- CONVENTIONS` or the releases page.
- Pinned installs change only when the user moves the pin (`CONTRIBUTING/VERSIONING.md`).
