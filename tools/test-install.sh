#!/usr/bin/env bash
# Smoke-test install.sh against a throwaway $HOME. Never touches the real one.
set -euo pipefail
cd "$(dirname "$0")/.."
repo=$PWD

fake=$(mktemp -d)
trap 'rm -rf "$fake"' EXIT
export HOME=$fake NO_COLOR=1
fail() { echo "FAIL: $*" >&2; exit 1; }

mkdir -p "$HOME/.claude" "$HOME/.codex"
echo 'user rules' >"$HOME/.claude/CLAUDE.md"

./install.sh >/dev/null
[[ $(readlink -f "$HOME/.claude/CLAUDE.md") == "$repo/global/AGENTS.md" ]] || fail "claude rules not linked"
[[ $(readlink -f "$HOME/.codex/AGENTS.md") == "$repo/global/AGENTS.md" ]] || fail "codex rules not linked"
[[ -f $HOME/.claude/skills/szmelc-conventions/SKILL.md ]] || fail "meta skill not linked"
[[ -f $HOME/.codex/skills/deep/SKILL.md ]] || fail "deep skill not linked"
[[ ! -e $HOME/.gemini ]] || fail "undetected harness was touched"
compgen -G "$HOME/.claude/CLAUDE.md.bak.*" >/dev/null || fail "existing file not backed up"

./install.sh >/dev/null # idempotent: no new backups
(($(compgen -G "$HOME/.claude/CLAUDE.md.bak.*" | wc -l) == 1)) || fail "re-install created extra backups"

./install.sh status --json | jq -e '.targets | length == 6 and all(.state == "linked")' >/dev/null || fail "status --json"

./install.sh uninstall >/dev/null
[[ $(cat "$HOME/.claude/CLAUDE.md") == 'user rules' ]] || fail "backup not restored"
[[ ! -e $HOME/.codex/AGENTS.md ]] || fail "codex link not removed"
[[ ! -e $HOME/.config/szmelc/conventions ]] || fail "home link not removed"

proj=$HOME/proj
mkdir -p "$proj"
./install.sh project "$proj" >/dev/null
for f in AGENTS.md CLAUDE.md GEMINI.md .cursor/rules/szmelc-conventions.mdc .github/instructions/szmelc-conventions.instructions.md .kiro/steering/szmelc-conventions.md; do
  [[ -f $proj/$f ]] || fail "project file missing: $f"
done

echo "install smoke test OK"
