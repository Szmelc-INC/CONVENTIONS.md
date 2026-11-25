# CONVENTIONS.md
Global Szmelc conventions for everything: humans and AI agents.

## Layout
```
INDEX.md            map: every rule file + when to load it (agents read only this first)
<category>/         a domain: claude, workflow, design, interfaces, packaging, ...
  <subcategory>.md  one topic, one file, starts with "> Load when: ..."
_template/rule.md   copy this to add a rule file
tools/check.sh      validates the structure (runs in CI)
```

## Rules of this repo
1. One topic = one file. One rule = one line.
2. Every rule file starts with `# Title` and `> Load when: <trigger>`.
3. Every rule file is listed in `INDEX.md` with the same trigger.
4. Never duplicate a rule; reference it by path (`design/colors.md`).
5. New domain → new directory. New topic → copy `_template/rule.md`.

## Install (Claude Code)
```sh
git clone https://github.com/Szmelc-INC/conventions.md ~/.claude/conventions
ln -sf ~/.claude/conventions/claude/CLAUDE.md ~/.claude/CLAUDE.md
mkdir -p ~/.claude/skills && ln -sfn ~/.claude/conventions/claude/skills/deep ~/.claude/skills/deep
```
Update: `git -C ~/.claude/conventions pull`.

Agents load rules lazily: `INDEX.md` once, then only matching files. Do not `@import` rule files into `CLAUDE.md`; imports load every session and defeat the point.
