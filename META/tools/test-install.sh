#!/usr/bin/env bash
# Smoke-test install.sh against a throwaway $HOME. Never touches the real one.
set -euo pipefail
cd "$(dirname "$0")/../.."
fake=$(mktemp -d)
trap 'rm -rf "$fake"' EXIT
export HOME=$fake NO_COLOR=1
fail() { echo "FAIL: $*" >&2; exit 1; }

mkdir -p "$HOME/.claude" "$HOME/.codex"
printf 'user rules\n' >"$HOME/.claude/CLAUDE.md"

./install.sh --profile neutral --only claude,codex >/dev/null
[[ ! -L $HOME/.claude/CLAUDE.md ]] || fail "claude rules replaced with a symlink"
grep -qF 'user rules' "$HOME/.claude/CLAUDE.md" || fail "existing claude rules were lost"
grep -qF '<!-- conventions:begin -->' "$HOME/.claude/CLAUDE.md" || fail "claude managed block missing"
[[ -f $HOME/.codex/AGENTS.md ]] || fail "codex rules file not created"
[[ -f $HOME/.claude/skills/conventions/SKILL.md ]] || fail "neutral skill not linked"
[[ -L $HOME/.claude/skills/szmelc-conventions ]] || fail "legacy skill alias not installed"
[[ -f $HOME/.claude/skills/deep/SKILL.md ]] || fail "deep skill not linked"
[[ ! -e $HOME/.gemini ]] || fail "undetected harness was touched"
! compgen -G "$HOME/.claude/CLAUDE.md.bak.*" >/dev/null || fail "default install created a backup"

./install.sh --profile neutral --only claude,codex >/dev/null
[[ $(grep -cF '<!-- conventions:begin -->' "$HOME/.claude/CLAUDE.md") == 1 ]] || fail "re-install duplicated the managed block"
./install.sh status --only claude,codex --json | jq -e '.targets | length == 8 and all(.state == "linked" or .state == "managed")' >/dev/null || fail "status --json"

./install.sh uninstall --only claude,codex >/dev/null
[[ $(cat "$HOME/.claude/CLAUDE.md") == 'user rules' ]] || fail "uninstall changed user rules"
[[ -f $HOME/.codex/AGENTS.md && ! -s $HOME/.codex/AGENTS.md ]] || fail "uninstall did not remove only the codex block"
[[ ! -e $HOME/.claude/skills/conventions ]] || fail "skill link not removed"
[[ ! -e $HOME/.config/conventions ]] || fail "home link not removed"

# Replace mode remains available when a user explicitly opts into links.
./install.sh --profile neutral --only claude --replace >/dev/null
[[ -L $HOME/.claude/CLAUDE.md ]] || fail "replace mode did not install a link"
compgen -G "$HOME/.claude/CLAUDE.md.bak.*" >/dev/null || fail "replace mode did not back up user rules"
./install.sh uninstall --only claude >/dev/null
[[ $(cat "$HOME/.claude/CLAUDE.md") == 'user rules' ]] || fail "replace uninstall did not restore user rules"

# Existing Kiro steering frontmatter and user text survive a managed block cycle.
mkdir -p "$HOME/.kiro/steering"
cat >"$HOME/.kiro/steering/szmelc-conventions.md" <<'EOF'
---
inclusion: manual
---
user steering
EOF
./install.sh --profile neutral --only kiro >/dev/null
grep -qF 'inclusion: manual' "$HOME/.kiro/steering/szmelc-conventions.md" || fail "Kiro frontmatter changed"
grep -qF 'user steering' "$HOME/.kiro/steering/szmelc-conventions.md" || fail "Kiro steering was lost"
./install.sh uninstall --only kiro >/dev/null
[[ $(cat "$HOME/.kiro/steering/szmelc-conventions.md") == $'---\ninclusion: manual\n---\nuser steering' ]] || fail "Kiro uninstall changed user content"

proj=$HOME/proj
mkdir -p "$proj"
./install.sh --profile szmelc project "$proj" >/dev/null
for f in AGENTS.md CLAUDE.md GEMINI.md .cursor/rules/szmelc-conventions.mdc .github/instructions/szmelc-conventions.instructions.md .kiro/steering/szmelc-conventions.md; do
  [[ -f $proj/$f ]] || fail "project file missing: $f"
done

# Exercise every supported harness with an isolated HOME, including harnesses
# that are not present in the host environment.
for harness in claude codex gemini qwen opencode kiro windsurf grok jcode agents; do
  export HOME="$fake/$harness"
  mkdir -p "$HOME"
  ./install.sh --profile neutral --only "$harness" >/dev/null
  ./install.sh status --only "$harness" --json |
    jq -e --arg harness "$harness" '.targets | length > 0 and all(.harness == $harness and (.state == "linked" or .state == "managed"))' >/dev/null || fail "$harness status after install"
  ./install.sh uninstall --only "$harness" >/dev/null
  ./install.sh status --only "$harness" --json |
    jq -e '.targets | all(.state != "linked" and .state != "managed")' >/dev/null || fail "$harness status after uninstall"
done

echo "install smoke test OK"
