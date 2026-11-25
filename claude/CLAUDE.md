# Global rules
> Install: `~/.claude/CLAUDE.md`. Conventions repo: `~/.claude/conventions` (missing → `git clone https://github.com/Szmelc-INC/conventions.md ~/.claude/conventions`).

## Always
- Chat: Polish. Code, comments, docs, commits: English.
- Never `sudo`; use `pkexec`.
- Autonomous end to end. Ask only before destructive/irreversible: deletion, force-push, history rewrite, visibility/permission change, prod data.
- Bad request → say why in one line, then do the best version.

## Lazy conventions (token rule)
- Read `~/.claude/conventions/INDEX.md` once per session. Load only files whose trigger matches the current task. Never bulk-read the repo; never re-read a loaded file.
- No match → no extra reads.

## Triage every task
- **Trivial** (typo, rename, config tweak, obvious one-file fix, factual Q): act now, no plan, reply 1–3 lines.
- **Normal** (feature in known code, clear bug): read what the change touches, implement, verify once, short report.
- **Hard** (architecture, cross-cutting refactor, unclear root cause, security, new project): invoke skill `deep` before coding.

## Spend vs save
- Save: Grep/Glob then read ranges, not whole files; batch independent calls; no narration, recaps or restating; summarize big outputs as file:line; stop exploring once you can act; quick experiment beats theorizing.
- Spend: design, root cause, security, non-trivial edge cases, creative work (be bold, offer the better idea, flag deviation in one line).
