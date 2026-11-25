# AGENTS
> Load when: installing the conventions into an agent harness, writing agent instruction files or skills, or deciding on subagents.

Everything an AI agent consumes: the always-on global rules, skills, per-tool adapters and the rules about agent files themselves.

## Contents
| Path | Role |
|---|---|
| `AGENTS/global/AGENTS.md` | Always-on rules; linked as `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `QWEN.md` by `install.sh` |
| `AGENTS/rules/` | Stable agent rules: subagents, agent instruction files, skills |
| `AGENTS/skills/` | Extra Agent Skills (`deep`); the meta skill is the repo root `SKILL.md` |
| `AGENTS/adapters/` | Generated Cursor `.mdc`, Copilot `.instructions.md`, Kiro steering from the global rules |

## How agents load conventions
1. Global rules are always on (installed as global instructions).
2. Skill `szmelc-conventions` (root `SKILL.md`) is the entry point; it points at `INDEX.md`.
3. `INDEX.md` once per session, then only files whose `Load when` matches. Never bulk-read.
4. Precedence: user's direct instruction > project `AGENTS.md`/`CLAUDE.md` > stable rules > experimental.

## Install
- `./install.sh` links global rules and skills into every detected harness; `./install.sh status` shows state. Harness table: `HUMANS/README.md`.
- `./install.sh project <dir>` drops adapters and an `AGENTS.md` skeleton into a project.
- After upgrading from the pre-core layout, re-run `./install.sh`: links to old paths are replaced in place.

## This repo
- Root `AGENTS.md` (imported by `CLAUDE.md`, `GEMINI.md`) holds instructions for agents working on this repo, plus a generated map of `AGENTS/`.
