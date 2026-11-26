---
id: conventions.code.shell
---
# Shell scripts
> Load when: writing or editing a shell script (bash, zsh, POSIX sh) or an installer.

- Shebang `#!/usr/bin/env bash` (`sh`, `zsh` when that is the target); bash scripts start with `set -euo pipefail`.
- POSIX `sh` where it costs nothing; otherwise say which shell is required.
- Tunables in a commented block at the top; the logic below never hardcodes them.
- Output through helpers with the CLI vocabulary (`CONVENTIONS/INTERFACES/CLI.md`); colors via `tput`, off when not a TTY or `NO_COLOR` is set.
- Missing tool → fallback chain (`ss` → `netstat` → `lsof`), then a clear error naming what to install.
- Idempotent: re-running converges, never duplicates or breaks state.
- `command -v`, never `which`, to test for a tool.
- Portable scripts (macOS, BSD): POSIX utility flags only; no GNU-only forms (`readlink -f`, `date -d`, `stat -c`, `grep -P`).
- Portable scripts: no `sed -i` (GNU and BSD syntax differ); write to a `mktemp` file and `mv`.
- Portable scripts: resolve paths with `cd -P -- "$d" && pwd -P`.
- A script that needs GNU tools says so at the top.
- Quote every expansion; `$HOME` and XDG vars, never `/home/<user>`; temp files via `mktemp`, removed on exit (`trap`).
- `bash -n` / `sh -n` and `shellcheck` clean before delivery.
- Root: never use an unsafe privilege shortcut; use `{{profile.privilege_tool}}` for the one step that needs it.
