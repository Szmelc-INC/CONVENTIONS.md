# HUMANS
> Load when: a person asks how to install, browse or use the conventions.

The human side: how to get the conventions into your tools and read them.

## Browse

- Site: <{{profile.site_url}}>. One tab per core with its guide and nested category groups; every rule readable inline, copyable as Markdown or raw URL; copyable prompts; the {{profile.project_name}} projects index; themes dark, light, mono, terminal. A "Compatible with" carousel under the title lists the third-party formats and tools (`COMPATIBILITY.md`); hover or focus stops it, click opens details. On the CONVENTIONS tab, `All · Third-party · {{profile.brand}}` filters rules by origin. Keys: `/` filter (searches rule text, flags tabs with hits), `1`-`9` and `0` tabs (arrows inside the tab bar), `e` expand all, `t` theme, `esc` clear; filter hits are highlighted. Deep-links: `#<core>`, `#<core>/<category>/`, `#<path>`, `#compat/<id>` or `#install` (e.g. `#CONVENTIONS/GITHUB/RELEASES/`, `#CONVENTIONS/DESIGN/COLORS.md`).
- Repo root: one map per core (`CONVENTIONS.md`, `AGENTS.md`, `HUMANS.md`, `CONTRIBUTING.md`, `META.md`, `TEMPLATES.md`), each pointing at `X/README.md`. Compatible third-party formats and tools: `COMPATIBILITY.md`.

## Install

```sh
git clone <repository-url> <install-path>
<install-path>/install.sh status   # what would be linked
<install-path>/install.sh status --json   # the same report, machine-readable
<install-path>/install.sh          # link into every detected harness
```

- Existing global instruction files are preserved; the installer updates only its marked block. `install.sh uninstall` removes that block. `--replace` opts into backed-up file replacement.
- Pick harnesses: `--only claude,codex`. Preview: `--dry-run`. Into a project: `install.sh project <dir>`.
- Update: run `git -C <install-path> pull`, then re-run `install.sh` when the layout changed.
- Automation reads `status --json` instead of the colored table: scripts and CI verify the targets before and after an install.

```json
{"repo": "<install-path>", "targets": [
  {"harness": "claude", "kind": "rules", "path": "~/.claude/CLAUDE.md", "state": "managed"},
  {"harness": "claude", "kind": "skill", "path": "~/.claude/skills/conventions", "state": "linked"}
]}
```

| Harness | Global rules | Skills root |
|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/skills` |
| Codex | `~/.codex/AGENTS.md` | `~/.codex/skills` |
| Gemini CLI / Antigravity | `~/.gemini/GEMINI.md` | `~/.gemini/config/skills` (unverified) |
| Qwen Code | `~/.qwen/QWEN.md` (unverified) | `~/.qwen/skills` |
| OpenCode | `~/.config/opencode/AGENTS.md` (unverified) | — |
| Kiro | `~/.kiro/steering/<skill-name>.md` | `~/.kiro/skills` |
| Windsurf | `~/.codeium/windsurf/memories/global_rules.md` (unverified) | — |
| Grok, jcode, `~/.agents` | — | `~/.grok/skills`, `~/.jcode/skills`, `~/.agents/skills` |
| Cursor, Copilot | per project: `install.sh project <dir>` | — |
| Aider, web chats | `aider --read CONVENTIONS.md`, or paste/upload `CONVENTIONS.md` | — |

## Contribute
Quick start: `CONTRIBUTING/101.md`. Ready agent prompts: `CONTRIBUTING/PROMPTS.md`. Writing a prompt for an agent: `AGENTS/PROMPT/`. Branching, writing, naming, building and shipping a rule: `CONTRIBUTING/README.md`.
