# Projects
> Load when: planning work across issues, creating or editing a GitHub Project board.

- Projects (v2) only; one per org or per initiative, not one per repo.
- Items are issues and PRs; draft items only for quick capture, converted to issues before work starts.
- Fields: Status (Todo, In progress, Done), Priority (P0–P2), Size (S/M/L), Iteration when working in cycles.
- Views: Board grouped by Status, Table for triage, Roadmap by Iteration or dates.
- Built-in workflows: auto-add matching repo issues/PRs, item added → Todo, item closed and PR merged → Done.
- Status follows issues and PRs (open, linked PR, closed), not hand-moved cards.
- Link the project to its repos (`gh project link`).
- CLI: `gh project view/item-list/item-add/item-edit/field-list --owner <org>`; needs the `project` scope (`gh auth refresh -s project`).
