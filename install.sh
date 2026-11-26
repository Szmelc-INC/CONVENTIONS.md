#!/usr/bin/env bash
# Install Szmelc conventions into every detected agent harness via symlinks.
# Existing files are never overwritten: they are moved to <path>.bak.<timestamp>.
set -euo pipefail

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
LINK_HOME="$HOME/.config/szmelc/conventions"
SKILL=szmelc-conventions
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
$(c "$ACCENT" "install.sh") $(c "$SILVER" "— link Szmelc conventions into agent harnesses")

$(c "$ACCENT" Usage)
  ./install.sh [command] [flags]

$(c "$ACCENT" Commands)
  install            link global rules + skills into detected harnesses (default)
  uninstall          remove links into this repo, restore newest backups
  status             show every target and its state
  project <dir>      add Cursor/Copilot/Kiro adapters + AGENTS.md skeleton to a project

$(c "$ACCENT" Flags)
  -o, --only LIST    comma list of harnesses: ${HARNESSES// /,}
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
while (($#)); do
  case $1 in
    install | uninstall | status) cmd=$1 ;;
    project) cmd=project; project_dir=${2:?project needs a directory}; shift ;;
    -o | --only) only=${2:?--only needs a list}; shift ;;
    -a | --all) all=1 ;;
    -n | --dry-run) dry=1 ;;
    --json) json=1 ;;
    --no-color) color=0 ;;
    -h | --help | help) usage; exit 0 ;;
    *) die "unknown argument: $1 (see --help)" ;;
  esac
  shift
done
if [[ -n $only ]]; then
  for h in ${only//,/ }; do [[ " $HARNESSES " == *" $h "* ]] || die "unknown harness: $h"; done
fi

run() {
  if ((dry)); then say "$SILVER" dry-run "$*"; else "$@"; fi
}

# Base path that installed links point to: the stable ~/.config link when it resolves here.
base() {
  if [[ $(readlink -f "$LINK_HOME" 2>/dev/null) == "$REPO" ]]; then echo "$LINK_HOME"; else echo "$REPO"; fi
}

selected() { # selected <harness> <home>
  [[ -n $only && ",$only," != *",$1,"* ]] && return 1
  [[ -n $only ]] && return 0
  ((all)) || [[ -d $HOME/$2 ]]
}

# Expand TARGETS into "harness|kind|dest|src" lines (skills → one line per skill).
expand() {
  local t h home kind dest src b
  b=$(base)
  for t in "${TARGETS[@]}"; do
    IFS='|' read -r h home kind dest src <<<"$t"
    selected "$h" "$home" || continue
    if [[ $kind == skills ]]; then
      echo "$h|skill|$HOME/$dest/$SKILL|$b"
      echo "$h|skill|$HOME/$dest/deep|$b/AGENTS/skills/deep"
    else
      echo "$h|$kind|$HOME/$dest|$b/$src"
    fi
  done
}

ours() { # ours <path>: symlink pointing into this repo (directly or via LINK_HOME)
  [[ -L $1 ]] || return 1
  local t
  t=$(readlink "$1")
  [[ $t == "$REPO"* || $t == "$LINK_HOME"* ]]
}

state() {
  if ours "$1"; then echo linked
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
  if [[ $REPO != "$LINK_HOME" ]]; then
    if [[ -L $LINK_HOME || ! -e $LINK_HOME ]]; then
      link "$REPO" "$LINK_HOME"
    else
      say "$DANGER" warn "$LINK_HOME exists and is not this repo; links will point to $REPO"
    fi
  fi
  local h kind dst src n=0
  while IFS='|' read -r h kind dst src; do
    link "$src" "$dst"
    n=$((n + 1))
  done < <(expand)
  ((n)) || say "$DANGER" warn "no harness detected; use --all or --only"
  say "$HI" " done " "$n targets. Update later: git -C $LINK_HOME pull"
}

do_uninstall() {
  local h kind dst src
  while IFS='|' read -r h kind dst src; do unlink_restore "$dst"; done < <(expand)
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
    case $s in linked) s=$(c "$ACCENT" "$(printf '%-12s' "$s")") ;; *) s=$(c "$SILVER" "$(printf '%-12s' "$s")") ;; esac
    printf '%-9s  %-6s  %s  %s\n' "$h" "$kind" "$s" "${dst/#$HOME/\~}"
  done < <(expand)
}

do_project() {
  local d=$1 f
  [[ -d $d ]] || die "not a directory: $d"
  copy() { # copy <src> <dest>: never overwrite
    if [[ -e $2 ]]; then say "$SILVER" skip "$2 exists"; return; fi
    run mkdir -p "$(dirname "$2")"
    run cp "$REPO/$1" "$2"
    say "$ACCENT" add "$2"
  }
  copy AGENTS/adapters/cursor/szmelc-conventions.mdc "$d/.cursor/rules/szmelc-conventions.mdc"
  copy AGENTS/adapters/copilot/szmelc-conventions.instructions.md "$d/.github/instructions/szmelc-conventions.instructions.md"
  copy AGENTS/adapters/kiro/szmelc-conventions.md "$d/.kiro/steering/szmelc-conventions.md"
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
