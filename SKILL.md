---
name: szmelc-conventions
description: Szmelc global conventions for humans and AI agents. Covers language rules, git/PR/CI flow, branch lanes (main/testing/experimental/legacy), repo metadata, notifications, verification, subagent policy, colors, CLI/TUI design, Arch/Nix packaging, and how to write AGENTS.md, CLAUDE.md, SKILL.md and llms.txt files. Use at the start of any coding, repo, release, UI or packaging task in a Szmelc project, when creating a repo or agent file, or when asked which convention applies. Loads only the rule files whose trigger matches the task.
license: MIT
compatibility: Any harness that reads Agent Skills (Claude Code, Codex, Gemini/Antigravity, Qwen Code, Kiro, Grok, jcode) or plain AGENTS.md. Needs file read access to this repo.
metadata:
  repo: https://github.com/Szmelc-INC/CONVENTIONS.md
  install-path: ~/.config/szmelc/conventions
  index: INDEX.md
---

# Szmelc conventions
Entry point. This directory is the conventions repo; every path below is relative to it.

## Use
1. Apply `AGENTS/global/AGENTS.md` (always-on rules) if your harness did not already load it as global instructions.
2. Read `INDEX.md` once per session. Load only files whose "Load when" matches the task. Never bulk-read; never re-read.
3. `CONVENTIONS/experimental/` only when the user opts in. `CONVENTIONS/legacy/` only when asked about history.
4. Conflict → user's direct instruction > project `AGENTS.md`/`CLAUDE.md` > stable rules here > experimental.

## Formats
| Need | File |
|---|---|
| Always-on rules, any harness | `AGENTS/global/AGENTS.md` |
| Lazy index (human/agent) | `INDEX.md` |
| Machine index | `index.json` (schema: `META/schema/index.schema.json`) |
| LLM web index | `llms.txt` |
| All stable rules in one file (aider `--read`, web chats) | `CONVENTIONS.md` |
| Browsable site (tabs per category + projects index) | <https://szmelc-inc.github.io/CONVENTIONS.md/> (`META/tools/site.sh`) |
| Cursor / Copilot / Kiro rule files | `AGENTS/adapters/` |
| Skills | `SKILL.md` (this), `AGENTS/skills/deep/SKILL.md` |
| Templates | `META/templates/` |

## Install / update
- `./install.sh` links global rules and skills into every detected harness; `./install.sh status` shows what is linked.
- `./install.sh project <dir>` drops Cursor/Copilot/Kiro adapters and an `AGENTS.md` skeleton into a project.
- Update: `git -C ~/.config/szmelc/conventions pull`.

## Change a convention
- Edit sources only, then `META/tools/build.sh && META/tools/check.sh`. Rules of this repo: `README.md`.
- Branch lanes and promotion/demotion: `CONVENTIONS/workflow/branches.md`.
