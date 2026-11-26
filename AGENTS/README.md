# AGENTS
> Load when: installing the conventions into an agent harness, deciding on subagents, model or effort, or writing a prompt for an agent.

Everything an AI agent consumes: the always-on global rules, agent behaviour rules, prompt engineering, skills and per-tool adapters. Formats of agent files (`AGENTS.md`, `CLAUDE.md`, `SKILL.md`, `llms.txt`) live in `CONVENTIONS/SPECS/THIRD-PARTY/`.

## Contents
| Path | Role |
|---|---|
| `AGENTS/global/AGENTS.md` | Always-on rules; linked as `CLAUDE.md`, `AGENTS.md`, `GEMINI.md`, `QWEN.md` by `install.sh` |
| `AGENTS/RULES/` | Agent behaviour: subagents, token efficiency |
| `AGENTS/PROMPT/` | Prompt engineering 101: how to write, test and check prompts; paste-ready prompt library |
| `AGENTS/skills/` | Extra Agent Skills (`deep`); the meta skill is the repo root `SKILL.md` |
| `AGENTS/adapters/` | Generated Cursor `.mdc`, Copilot `.instructions.md`, Kiro steering from the global rules |

## How agents load conventions
1. Global rules are always on (installed as global instructions).
2. Skill `{{profile.skill_name}}` (root `SKILL.md`) is the entry point; it points at `INDEX.md`.
3. `INDEX.md` once per session, then only files whose `Load when` matches. Never bulk-read.
4. Precedence: user's direct instruction > project `AGENTS.md`/`CLAUDE.md` > stable rules > experimental.

## Experimental mode bundles
- A mode bundle is opt-in context for one named task mode; it does not change the default instruction set.
- Load a file from `AGENTS/modes/` only when the user explicitly requests that mode. Then load only its listed stable rule IDs from `INDEX.md`.
- Mode bundles cannot override direct user instructions, project instructions or stable rules. If a listed ID is missing, stop and report the stale bundle.

## Install
- `./install.sh` links global rules and skills into every detected harness; `./install.sh status` shows state. Harness table: `HUMANS/README.md`.
- `./install.sh project <dir>` drops adapters and an `AGENTS.md` skeleton into a project.
- After upgrading from the pre-core layout, re-run `./install.sh`: links to old paths are replaced in place.

## This repo
- Root `AGENTS.md` (imported by `CLAUDE.md`, `GEMINI.md`) holds instructions for agents working on this repo, plus a generated map of `AGENTS/`.
