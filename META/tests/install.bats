#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../.." && pwd)"
  TEST_ROOT="$(mktemp -d)"
  export NO_COLOR=1
  use_test_home "$TEST_ROOT/home"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

# profile_field <profile> <key>: a [profile] value of PROFILES/<profile>/profile.toml.
profile_field() {
  awk -F '"' -v key="$2" '$1 ~ "^[[:space:]]*" key "[[:space:]]*=" {print $2; exit}' "$REPO_ROOT/PROFILES/$1/profile.toml"
}

# The first profile whose adapters carry their own name; empty when there is none.
profile_with_alias() {
  local file id
  for file in "$REPO_ROOT"/PROFILES/*/profile.toml; do
    id=$(basename "$(dirname "$file")")
    [[ -n "$(profile_field "$id" adapter_name)" && "$(profile_field "$id" adapter_name)" != "$(profile_field "$id" skill_name)" ]] && { echo "$id"; return; }
  done
}

use_test_home() {
  export HOME="$1"
  export XDG_CONFIG_HOME="$HOME/.config"
  export XDG_DATA_HOME="$HOME/.local/share"
  export XDG_STATE_HOME="$HOME/.local/state"
  mkdir -p "$HOME"
}

@test "managed global install is idempotent and uninstall preserves user rules" {
  mkdir -p "$HOME/.claude" "$HOME/.codex"
  printf 'user rules\n' >"$HOME/.claude/CLAUDE.md"

  run "$REPO_ROOT/install.sh" --profile neutral --only claude,codex
  [ "$status" -eq 0 ]
  [ ! -L "$HOME/.claude/CLAUDE.md" ]
  grep -qF 'user rules' "$HOME/.claude/CLAUDE.md"
  grep -qF '<!-- conventions:begin -->' "$HOME/.claude/CLAUDE.md"
  [ -f "$HOME/.codex/AGENTS.md" ]
  [ -f "$HOME/.claude/skills/conventions/SKILL.md" ]
  [ ! -e "$HOME/.claude/skills/szmelc-conventions" ]
  [ -f "$HOME/.claude/skills/deep/SKILL.md" ]
  [ ! -e "$HOME/.gemini" ]
  ! compgen -G "$HOME/.claude/CLAUDE.md.bak.*" >/dev/null

  run "$REPO_ROOT/install.sh" --profile neutral --only claude,codex
  [ "$status" -eq 0 ]
  [ "$(grep -cF '<!-- conventions:begin -->' "$HOME/.claude/CLAUDE.md")" -eq 1 ]

  run "$REPO_ROOT/install.sh" status --only claude,codex --json
  [ "$status" -eq 0 ]
  printf '%s' "$output" | jq -e '.targets | length == 6 and all(.state == "linked" or .state == "managed")' >/dev/null

  run "$REPO_ROOT/install.sh" uninstall --only claude,codex
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.claude/CLAUDE.md")" = 'user rules' ]
  [ -f "$HOME/.codex/AGENTS.md" ]
  [ ! -s "$HOME/.codex/AGENTS.md" ]
  [ ! -e "$HOME/.claude/skills/conventions" ]
  [ ! -e "$HOME/.config/conventions" ]
}

@test "replace mode backs up and restores an existing instruction file" {
  mkdir -p "$HOME/.claude"
  printf 'user rules\n' >"$HOME/.claude/CLAUDE.md"

  run "$REPO_ROOT/install.sh" --profile neutral --only claude --replace
  [ "$status" -eq 0 ]
  [ -L "$HOME/.claude/CLAUDE.md" ]
  compgen -G "$HOME/.claude/CLAUDE.md.bak.*" >/dev/null

  run "$REPO_ROOT/install.sh" uninstall --only claude
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.claude/CLAUDE.md")" = 'user rules' ]
}

@test "Kiro install and uninstall preserve steering frontmatter and user text" {
  mkdir -p "$HOME/.kiro/steering"
  cat >"$HOME/.kiro/steering/conventions.md" <<'EOF'
---
inclusion: manual
---
user steering
EOF

  run "$REPO_ROOT/install.sh" --profile neutral --only kiro
  [ "$status" -eq 0 ]
  grep -qF 'inclusion: manual' "$HOME/.kiro/steering/conventions.md"
  grep -qF 'user steering' "$HOME/.kiro/steering/conventions.md"

  run "$REPO_ROOT/install.sh" uninstall --only kiro
  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.kiro/steering/conventions.md")" = $'---\ninclusion: manual\n---\nuser steering' ]
}

@test "a profile with its own adapter name installs its alias and steering file" {
  profile=$(profile_with_alias)
  [ -n "$profile" ] || skip "no profile sets an adapter_name different from its skill_name"
  adapter=$(profile_field "$profile" adapter_name)
  mkdir -p "$HOME/.claude"

  run "$REPO_ROOT/install.sh" --profile "$profile" --only claude,kiro
  [ "$status" -eq 0 ]
  [ -L "$HOME/.claude/skills/$adapter" ]
  [ -f "$HOME/.kiro/steering/$adapter.md" ]
  grep -qF '<!-- conventions:begin -->' "$HOME/.kiro/steering/$adapter.md"

  run "$REPO_ROOT/install.sh" uninstall --only claude,kiro
  [ "$status" -eq 0 ]
  [ ! -e "$HOME/.claude/skills/$adapter" ]
}

@test "project install creates files for supported harnesses" {
  project="$HOME/project"
  mkdir -p "$project"

  run "$REPO_ROOT/install.sh" --profile neutral project "$project"
  [ "$status" -eq 0 ]
  for path in AGENTS.md CLAUDE.md GEMINI.md .cursor/rules/conventions.mdc .github/instructions/conventions.instructions.md .kiro/steering/conventions.md; do
    [ -f "$project/$path" ]
  done
}

@test "install, status, and uninstall work for every supported harness" {
  for harness in claude codex gemini qwen opencode kiro windsurf grok jcode agents; do
    use_test_home "$TEST_ROOT/$harness"

    run "$REPO_ROOT/install.sh" --profile neutral --only "$harness"
    [ "$status" -eq 0 ]

    run "$REPO_ROOT/install.sh" status --only "$harness" --json
    [ "$status" -eq 0 ]
    printf '%s' "$output" | jq -e --arg harness "$harness" '.targets | length > 0 and all(.harness == $harness and (.state == "linked" or .state == "managed"))' >/dev/null

    run "$REPO_ROOT/install.sh" uninstall --only "$harness"
    [ "$status" -eq 0 ]

    run "$REPO_ROOT/install.sh" status --only "$harness" --json
    [ "$status" -eq 0 ]
    printf '%s' "$output" | jq -e '.targets | all(.state != "linked" and .state != "managed")' >/dev/null
  done
}
