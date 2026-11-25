# HUMANS
> Load when: a person asks how to install, browse or use the conventions.

The human side: how to get the conventions into your tools and read them.

## Browse
- Site: <https://szmelc-inc.github.io/CONVENTIONS.md/>. One tab per core with its guide; every rule readable inline, copyable as Markdown or raw URL; the Szmelc projects index. Keys: `/` filter (searches rule text, flags tabs with hits), `1`-`9` tabs, `e` expand all, `esc` clear. Deep-links: `#<core>` or `#<path>` (e.g. `#CONVENTIONS/DESIGN/COLORS.md`).
- Repo root: one map per core (`CONVENTIONS.md`, `AGENTS.md`, `HUMANS.md`, `CONTRIBUTING.md`, `SZMELC.md`, `META.md`), each pointing at `X/README.md`.

## Install
```sh
git clone https://github.com/Szmelc-INC/CONVENTIONS.md ~/.config/szmelc/conventions
~/.config/szmelc/conventions/install.sh status   # what would be linked
~/.config/szmelc/conventions/install.sh          # link into every detected harness
```
- Existing files are moved to `*.bak.<timestamp>`, never overwritten; `install.sh uninstall` restores them.
- Pick harnesses: `--only claude,codex`. Preview: `--dry-run`. Into a project: `install.sh project <dir>`.
- Update: `git -C ~/.config/szmelc/conventions pull`, then re-run `install.sh` when the layout changed.

| Harness | Global rules | Skills root |
|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/skills` |
| Codex | `~/.codex/AGENTS.md` | `~/.codex/skills` |
| Gemini CLI / Antigravity | `~/.gemini/GEMINI.md` | `~/.gemini/config/skills` (unverified) |
| Qwen Code | `~/.qwen/QWEN.md` (unverified) | `~/.qwen/skills` |
| OpenCode | `~/.config/opencode/AGENTS.md` (unverified) | — |
| Kiro | `~/.kiro/steering/szmelc-conventions.md` | `~/.kiro/skills` |
| Windsurf | `~/.codeium/windsurf/memories/global_rules.md` (unverified) | — |
| Grok, jcode, `~/.agents` | — | `~/.grok/skills`, `~/.jcode/skills`, `~/.agents/skills` |
| Cursor, Copilot | per project: `install.sh project <dir>` | — |
| Aider, web chats | `aider --read CONVENTIONS.md`, or paste/upload `CONVENTIONS.md` | — |

## Contribute
Branching, writing, naming, building and shipping a rule: `CONTRIBUTING/README.md`.
