#!/usr/bin/env bash
# Install the selected conventions profile into detected agent harnesses.
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
PROFILE=neutral
PROFILE_DIR=''
PROFILE_OUT=''
LINK_HOME=''
SKILL=''
STAMP=$(date +%Y%m%d%H%M%S)

# harness|home (relative to $HOME)|kind|destination (relative to $HOME)|source (relative to repo)
# Paths marked "unverified" follow each tool's docs but were not observed loading on a real install.
TARGETS=(
  "claude|.claude|rules|.claude/CLAUDE.md|AGENTS/global/AGENTS.md"
  "claude|.claude|skills|.claude/skills|"
  "codex|.codex|rules|.codex/AGENTS.md|AGENTS/global/AGENTS.md"
  "codex|.codex|skills|.codex/skills|"
  "gemini|.gemini|rules|.gemini/GEMINI.md|AGENTS/global/AGENTS.md"
  "gemini|.gemini|skills|.gemini/config/skills|"
  "qwen|.qwen|rules|.qwen/QWEN.md|AGENTS/global/AGENTS.md"
  "qwen|.qwen|skills|.qwen/skills|"
  "opencode|.config/opencode|rules|.config/opencode/AGENTS.md|AGENTS/global/AGENTS.md"
  "kiro|.kiro|rules|.kiro/steering/szmelc-conventions.md|AGENTS/adapters/kiro/szmelc-conventions.md"
  "kiro|.kiro|skills|.kiro/skills|"
  "windsurf|.codeium/windsurf|rules|.codeium/windsurf/memories/global_rules.md|AGENTS/global/AGENTS.md"
  "grok|.grok|skills|.grok/skills|"
  "jcode|.jcode|skills|.jcode/skills|"
  "agents|.agents|skills|.agents/skills|"
)
HARNESSES="claude codex gemini qwen opencode kiro windsurf grok jcode agents"

# --- output ------------------------------------------------------------------
color=1
[[ -n ${NO_COLOR:-} || ! -t 1 ]] && color=0
c() { ((color)) && printf '\033[%sm%s\033[0m' "$1" "$2" || printf '%s' "$2"; }
ACCENT='1;38;2;31;138;138' SILVER='38;2;192;192;192' DANGER='38;2;184;58;58' HI='30;48;2;127;255;212'
say() { printf '%s %s\n' "$(c "$1" "$2")" "$3"; }
die() { say "$DANGER" error "$*" >&2; exit 1; }

usage() {
  cat <<EOF
$(c "$ACCENT" "install.sh") $(c "$SILVER" "— install conventions into agent harnesses")

$(c "$ACCENT" Usage)
  ./install.sh [command] [flags]

$(c "$ACCENT" Commands)
  install            add global rules + skills to detected harnesses (default)
  uninstall          remove managed blocks and links, restore newest backups
  status             show every target and its state
  project <dir>      add Cursor/Copilot/Kiro adapters + AGENTS.md skeleton to a project

$(c "$ACCENT" Flags)
  -o, --only LIST    comma list of harnesses: ${HARNESSES// /,}
      --profile NAME select a profile (default: neutral)
      --replace       replace global files with profile links (backs up existing files)
  -a, --all          also target harnesses whose home dir does not exist
  -n, --dry-run      print actions, change nothing
      --json         machine-readable status
      --no-color     disable colors (also: NO_COLOR=1)
  -h, --help         this help

$(c "$ACCENT" Examples)
  ./install.sh status
  ./install.sh --only claude,codex
  ./install.sh project ~/Projects/foo
EOF
}

# --- args --------------------------------------------------------------------
cmd=install only="" all=0 dry=0 json=0 project_dir=""
replace=0
while (($#)); do
  case $1 in
    install | uninstall | status) cmd=$1 ;;
    project) cmd=project; project_dir=${2:?project needs a directory}; shift ;;
    -o | --only) only=${2:?--only needs a list}; shift ;;
    -a | --all) all=1 ;;
    -n | --dry-run) dry=1 ;;
    --replace) replace=1 ;;
    --profile) PROFILE=${2:?--profile needs a name}; shift ;;
    --json) json=1 ;;
    --no-color) color=0 ;;
    -h | --help | help) usage; exit 0 ;;
    *) die "unknown argument: $1 (see --help)" ;;
  esac
  shift
done
[[ $PROFILE =~ ^[a-z0-9][a-z0-9-]*$ ]] || die "invalid profile name: $PROFILE"
PROFILE_DIR="$REPO/PROFILES/$PROFILE"
[[ -f $PROFILE_DIR/profile.toml ]] || die "profile not found: $PROFILE"
profile_value() {
  awk -v wanted="$2" '
    /^[[:space:]]*#/ { next }
    /^\[profile\][[:space:]]*$/ { in_profile=1; next }
    /^\[/ { in_profile=0 }
    in_profile {
      line=$0; eq=index(line, "="); if (!eq) next
      key=substr(line, 1, eq-1); gsub(/[[:space:]]/, "", key); if (key != wanted) next
      value=substr(line, eq+1); sub(/^[[:space:]]*/, "", value)
      if (substr(value, 1, 1) != "\"") next
      sub(/^"/, "", value); sub(/"[[:space:]]*$/, "", value); print value; exit
    }
  ' "$PROFILE_DIR/profile.toml"
}
SKILL=$(profile_value profile.toml skill_name)
install_path=$(profile_value profile.toml install_path)
[[ -n $SKILL && $SKILL =~ ^[a-z0-9]([a-z0-9-]{0,62}[a-z0-9])?$ ]] || die "profile $PROFILE has invalid skill_name"
[[ $install_path == '~/'* ]] || die "profile $PROFILE install_path must start with ~/"
LINK_HOME="$HOME/${install_path#~/}"
PROFILE_OUT="$PROFILE_DIR/rendered"
if [[ -n $only ]]; then
  for h in ${only//,/ }; do [[ " $HARNESSES " == *" $h "* ]] || die "unknown harness: $h"; done
fi

run() {
  if ((dry)); then say "$SILVER" dry-run "$*"; else "$@"; fi
}

selected() { # selected <harness> <home>
  [[ -n $only && ",$only," != *",$1,"* ]] && return 1
  [[ -n $only ]] && return 0
  ((all)) || [[ -d $HOME/$2 ]]
}

# Expand TARGETS into "harness|kind|dest|src" lines (skills → one line per skill).
expand() {
  local t h home kind dest src
  for t in "${TARGETS[@]}"; do
    IFS='|' read -r h home kind dest src <<<"$t"
    selected "$h" "$home" || continue
    if [[ $kind == skills ]]; then
      echo "$h|skill|$HOME/$dest/$SKILL|$PROFILE_OUT"
      if [[ $SKILL == conventions ]]; then echo "$h|skill|$HOME/$dest/szmelc-conventions|$PROFILE_OUT"; fi
      echo "$h|skill|$HOME/$dest/deep|$REPO/AGENTS/skills/deep"
    else
      echo "$h|$kind|$HOME/$dest|$PROFILE_OUT/$src"
    fi
  done
}

ours() { # ours <path>: symlink pointing into this repo (directly or via LINK_HOME)
  [[ -L $1 ]] || return 1
  local t
  t=$(readlink "$1")
  [[ $t == "$REPO" || $t == "$REPO/"* || $t == "$LINK_HOME" || $t == "$LINK_HOME/"* ]]
}

state() {
  if ours "$1"; then echo linked
  elif [[ -f $1 ]] && grep -qF '<!-- conventions:begin -->' "$1"; then echo managed
  elif [[ -L $1 ]]; then echo foreign-link
  elif [[ -e $1 ]]; then echo file
  else echo missing; fi
}

link() { # link <src> <dest>
  local src=$1 dst=$2
  if [[ -L $dst && $(readlink "$dst") == "$src" ]]; then say "$SILVER" ok "$dst"; return; fi
  if ours "$dst"; then
    # Our own link to an older layout path: replace it, nothing to back up.
    run rm "$dst"
  elif [[ -e $dst || -L $dst ]]; then
    run mv "$dst" "$dst.bak.$STAMP"
    say "$DANGER" backup "$dst → $dst.bak.$STAMP"
  fi
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
  say "$ACCENT" link "$dst → $src"
}

merge_block() { # merge_block <src> <dst>
  local src=$1 dst=$2 tmp dir body
  if ((dry)); then say "$SILVER" dry-run "update conventions block in $dst"; return; fi
  if [[ -L $dst ]]; then
    if ! ours "$dst"; then die "refusing to edit foreign symlink: $dst"; fi
    local backup
    backup=$(compgen -G "$dst.bak.*" | sort | tail -1 || true)
    rm "$dst"
    if [[ -n $backup ]]; then mv "$backup" "$dst"; else : >"$dst"; fi
  fi
  dir=$(dirname "$dst")
  mkdir -p "$dir"
  if [[ ! -e $dst ]]; then
    : >"$dst"
    case $src in
      */AGENTS/adapters/kiro/*) sed -n '1,3p' "$src" >"$dst" ;;
    esac
  fi
  if awk '/<!-- conventions:begin -->/{start++} /<!-- conventions:end -->/{end++} END{exit !(start==end && start<=1)}' "$dst"; then :; else
    die "unbalanced or duplicate conventions markers in $dst"
  fi
  body=$(mktemp "$dir/.conventions.XXXXXX")
  tmp=$(mktemp "$dir/.update.XXXXXX")
  {
    printf '%s\n' '<!-- conventions:begin -->'
    case $src in
      */AGENTS/adapters/kiro/*)
        awk 'BEGIN{front=0; closed=0} /^---[[:space:]]*$/{if(!front){front=1;next} if(!closed){closed=1;next}} closed && !/<!-- GENERATED by META\/tools\/build.sh/ {print}' "$src"
        ;;
      *) cat "$src" ;;
    esac
    printf '\n%s\n' '<!-- conventions:end -->'
  } >"$body"
  awk -v block="$body" '
    /<!-- conventions:begin -->/ { while ((getline line < block) > 0) print line; close(block); skipping=1; next }
    skipping && /<!-- conventions:end -->/ { skipping=0; next }
    !skipping { print }
    END { if (skipping) exit 2 }
  ' "$dst" >"$tmp" || { rm -f "$body" "$tmp"; die "could not replace conventions block in $dst"; }
  if ! grep -qF '<!-- conventions:begin -->' "$tmp"; then
    [[ ! -s $tmp || $(tail -c 1 "$tmp" | wc -l) -eq 1 ]] || printf '\n' >>"$tmp"
    cat "$body" >>"$tmp"
  fi
  mv "$tmp" "$dst"
  rm -f "$body"
  say "$ACCENT" update "$dst"
}

remove_block() { # remove_block <dst>
  local dst=$1 tmp dir
  [[ -f $dst && ! -L $dst ]] || return 0
  grep -qF '<!-- conventions:begin -->' "$dst" || return 0
  if ((dry)); then say "$SILVER" dry-run "remove conventions block from $dst"; return; fi
  dir=$(dirname "$dst")
  tmp=$(mktemp "$dir/.remove.XXXXXX")
  awk '
    /<!-- conventions:begin -->/ { skipping=1; next }
    skipping && /<!-- conventions:end -->/ { skipping=0; next }
    !skipping { print }
    END { if (skipping) exit 2 }
  ' "$dst" >"$tmp" || { rm -f "$tmp"; die "unbalanced conventions markers in $dst"; }
  mv "$tmp" "$dst"
  say "$ACCENT" remove "$dst conventions block"
}

unlink_restore() {
  local dst=$1 bak
  ours "$dst" || return 0
  run rm "$dst"
  say "$ACCENT" unlink "$dst"
  bak=$(compgen -G "$dst.bak.*" | sort | tail -1 || true)
  if [[ -n $bak ]]; then
    run mv "$bak" "$dst"
    say "$ACCENT" restore "$bak → $dst"
  fi
}

do_install() {
  if ((!dry)); then META/tools/build.sh --profile "$PROFILE" >/dev/null; fi
  if [[ $REPO != "$LINK_HOME" ]]; then
    if [[ -L $LINK_HOME || ! -e $LINK_HOME ]]; then
      link "$REPO" "$LINK_HOME"
    else
      say "$DANGER" warn "$LINK_HOME exists and is not this repo; links will point to $REPO"
    fi
  fi
  local h kind dst src n=0
  while IFS='|' read -r h kind dst src; do
    if [[ $kind == rules && $replace == 0 ]]; then merge_block "$src" "$dst"; else link "$src" "$dst"; fi
    n=$((n + 1))
  done < <(expand)
  ((n)) || say "$DANGER" warn "no harness detected; use --all or --only"
  say "$HI" " done " "$n targets. Update later: git -C $LINK_HOME pull"
}

do_uninstall() {
  local h kind dst src
  while IFS='|' read -r h kind dst src; do
    if [[ $kind == rules && ! -L $dst ]]; then remove_block "$dst"; else unlink_restore "$dst"; fi
  done < <(expand)
  [[ -L $LINK_HOME ]] && ours "$LINK_HOME" && { run rm "$LINK_HOME"; say "$ACCENT" unlink "$LINK_HOME"; }
  return 0
}

jstr() { local s=$1; s=${s//\\/\\\\}; s=${s//\"/\\\"}; printf '"%s"' "$s"; }

do_status() {
  local h kind dst src s first=1
  if ((json)); then
    printf '{"repo": %s, "targets": [' "$(jstr "$REPO")"
    while IFS='|' read -r h kind dst src; do
      ((first)) || printf ','
      first=0
      printf '\n  {"harness": "%s", "kind": "%s", "path": %s, "state": "%s"}' "$h" "$kind" "$(jstr "$dst")" "$(state "$dst")"
    done < <(expand)
    printf '\n]}\n'
    return
  fi
  printf '%s  %s  %s  %s\n' "$(c "$ACCENT" "$(printf '%-9s' HARNESS)")" "$(c "$ACCENT" "$(printf '%-6s' KIND)")" "$(c "$ACCENT" "$(printf '%-12s' STATE)")" "$(c "$ACCENT" PATH)"
  while IFS='|' read -r h kind dst src; do
    s=$(state "$dst")
    case $s in linked | managed) s=$(c "$ACCENT" "$(printf '%-12s' "$s")") ;; *) s=$(c "$SILVER" "$(printf '%-12s' "$s")") ;; esac
    printf '%-9s  %-6s  %s  %s\n' "$h" "$kind" "$s" "${dst/#$HOME/\~}"
  done < <(expand)
}

do_project() {
  local d=$1 f
  [[ -d $d ]] || die "not a directory: $d"
  if ((!dry)); then META/tools/build.sh --profile "$PROFILE" >/dev/null; fi
  copy() { # copy <src> <dest>: never overwrite
    if [[ -e $2 ]]; then say "$SILVER" skip "$2 exists"; return; fi
    run mkdir -p "$(dirname "$2")"
    run cp "$REPO/$1" "$2"
    say "$ACCENT" add "$2"
  }
  copy PROFILES/"$PROFILE"/rendered/AGENTS/adapters/cursor/szmelc-conventions.mdc "$d/.cursor/rules/szmelc-conventions.mdc"
  copy PROFILES/"$PROFILE"/rendered/AGENTS/adapters/copilot/szmelc-conventions.instructions.md "$d/.github/instructions/szmelc-conventions.instructions.md"
  copy PROFILES/"$PROFILE"/rendered/AGENTS/adapters/kiro/szmelc-conventions.md "$d/.kiro/steering/szmelc-conventions.md"
  copy TEMPLATES/AGENTS.md "$d/AGENTS.md"
  for f in CLAUDE.md GEMINI.md; do
    if [[ -e $d/$f ]]; then say "$SILVER" skip "$d/$f exists"
    elif ((dry)); then say "$SILVER" dry-run "write $d/$f"
    else printf '@AGENTS.md\n' >"$d/$f"; say "$ACCENT" add "$d/$f"; fi
  done
}

case $cmd in
  install) do_install ;;
  uninstall) do_uninstall ;;
  status) do_status ;;
  project) do_project "$project_dir" ;;
esac
