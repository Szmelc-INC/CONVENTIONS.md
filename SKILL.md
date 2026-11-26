---
name: {{profile.skill_name}}
description: {{profile.project_name}} global conventions for humans and AI agents. Covers language and writing rules, git/PR/CI flow, commits, branches, releases, repository layout, documentation, metadata, notifications, verification, agent behavior, prompts, colors, CLI/TUI/config design, naming, code, dotfiles, packaging, installers and agent instruction files. Use at the start of a coding, repository, release, UI or packaging task, when creating an agent file or prompt, or when asked which convention applies. Loads only matching rules.
license: MIT
compatibility: Any harness that reads Agent Skills (Claude Code, Codex, Gemini/Antigravity, Qwen Code, Kiro, Grok, jcode) or plain AGENTS.md. Needs file read access to this repo.
metadata:
  repo: {{profile.repository_url}}
  install-path: {{profile.install_path}}
  index: INDEX.md
---

# {{profile.project_name}} conventions
Entry point. This directory is the conventions repo; every path below is relative to it.

## Use
1. Apply `AGENTS/global/AGENTS.md` (always-on rules) if your harness did not already load it as global instructions.
2. Read `INDEX.md` once per session. Load only files whose "Load when" matches the task. Never bulk-read; never re-read.
3. `CONVENTIONS/EXPERIMENTAL/` only when the user opts in. `CONVENTIONS/LEGACY/` only when asked about history.
4. Conflict → user's direct instruction > project `AGENTS.md`/`CLAUDE.md` > stable rules here > experimental.

## Formats
| Need | File |
|---|---|
| Always-on rules, any harness | `AGENTS/global/AGENTS.md` |
| Lazy index (human/agent) | `INDEX.md` |
| Machine index | `index.json` (schema: `META/schema/index.schema.json`) |
| LLM web index | `llms.txt` |
| All stable rules in one file (aider `--read`, web chats) | `CONVENTIONS.md` |
| Browsable site (tabs per category + projects index) | <{{profile.site_url}}> (`META/tools/site.sh`) |
| Cursor / Copilot / Kiro rule files | `AGENTS/adapters/` |
| How to write a prompt; paste-ready prompts | `AGENTS/PROMPT/` |
| Skills | `SKILL.md` (this), `AGENTS/skills/deep/SKILL.md` |
| Templates | `TEMPLATES/` |
| Compatible third-party formats, specs, tools (versions, links) | `COMPATIBILITY.md` (source `META/compat/registry.toml`) |

## Install / update
- `./install.sh` installs the selected profile's global rules in marked blocks and links skills; `./install.sh status` shows both states.
- `./install.sh project <dir>` drops Cursor/Copilot/Kiro adapters and an `AGENTS.md` skeleton into a project.
- Update: `git -C {{profile.install_path}} pull`.

## Change a convention
- Edit sources only, then `META/tools/build.sh && META/tools/check.sh`. Where a rule goes, naming, flow: `CONTRIBUTING/README.md`.
- Branches and promotion/demotion: `CONVENTIONS/WORKFLOW/BRANCHES.md`.
