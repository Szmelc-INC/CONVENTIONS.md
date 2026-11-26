---
id: conventions.github.coding-agents
---
# Coding agents on GitHub
> Load when: assigning issues to a coding agent, @-mentioning an agent on GitHub, or running an agent from a workflow.

- Agents: Copilot coding agent (assign an issue; needs a paid Copilot plan), Claude Code / Codex GitHub apps or actions (@-mention or workflow).
- Agent PRs follow the same rules: titles per `CONVENTIONS/WORKFLOW/COMMITS.md`, flow per `CONVENTIONS/GITHUB/PULL-REQUESTS.md`.
- Branch names per `CONVENTIONS/WORKFLOW/BRANCHES.md` where the tool allows (e.g. a branch-prefix input); fixed tool prefixes are accepted.
- Agent PRs stay draft until checks are green; a human or the orchestrating agent reviews and merges, never the agent itself unasked.
- Instructions come from the repo `AGENTS.md`; `.github/copilot-instructions.md` and `.github/instructions/*.instructions.md` are generated from it (`CONVENTIONS/SPECS/THIRD-PARTY/AGENTS-MD.md`).
- Issue for an agent: one task, acceptance criteria, files or commands to run; same as for a human.
- Least-privilege tokens: repo-scoped, contents + pull requests + issues only; workflow `permissions:` set explicitly.
- Never put secrets in prompts, issues or comments; agents read them from Actions secrets only.
- Untrusted input (issues or comments from strangers) never triggers an agent with write access.
