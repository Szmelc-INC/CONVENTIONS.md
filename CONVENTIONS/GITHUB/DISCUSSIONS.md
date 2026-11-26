---
id: conventions.github.discussions
---
# Discussions
> Load when: enabling GitHub Discussions, choosing categories, or moving threads between issues and discussions.

- Enable only when the project has users beyond its maintainers (`gh repo edit --enable-discussions`); otherwise issues suffice.
- Categories: Announcements (maintainers post), Ideas, Q&A (answerable), Show and tell; delete unused defaults. Categories are web-UI only (no REST/GraphQL mutation).
- Issues are actionable work; questions, ideas and open-ended talk are discussions.
- Convert a non-actionable issue to a discussion; open an issue from a discussion once work is agreed, linking both ways.
- Accepted idea → proposal PR on an experimental branch (`CONVENTIONS/WORKFLOW/BRANCHES.md`); link the discussion in the PR.
- Q&A: mark the answer; turn repeated questions into docs.
- Release and breaking-change notes go to Announcements.
- CLI: `gh discussion list/view/create/comment` (preview); otherwise `gh api graphql`.
