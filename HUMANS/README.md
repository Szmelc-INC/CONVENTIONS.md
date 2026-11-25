# HUMANS
> Load when: a person asks how to install, browse, use or contribute to the conventions.

The human side: how to get the conventions into your tools, read them, and change them.

## Browse
- Site: <https://szmelc-inc.github.io/CONVENTIONS.md/>. One tab per core, rendered core guides, rule cards, the Szmelc projects index. `/` filters, `#core` deep-links.
- Repo root: one map per core (`CONVENTIONS.md`, `AGENTS.md`, `HUMANS.md`, `SZMELC.md`, `META.md`), each pointing at `X/README.md`.

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
1. Branch from the right lane: `testing` (stable), `experimental` (proposals), `legacy` (archive).
2. Edit sources only; generated files are rebuilt by `META/tools/build.sh`.
3. `META/tools/build.sh && META/tools/check.sh` must pass; CI runs the same plus shellcheck and the installer smoke test.
4. PR into the lane, then lane into `main`. Rules: `CONVENTIONS/workflow/branches.md`, `CONVENTIONS/workflow/git-pr-ci.md`.
