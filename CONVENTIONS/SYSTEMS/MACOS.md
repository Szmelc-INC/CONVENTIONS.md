---
id: conventions.systems.macos
---
# macOS
> Load when: supporting macOS, or writing scripts or paths that must also run on macOS.

- Install via Nix (`CONVENTIONS/SYSTEMS/NIX.md`) or Homebrew; release artifacts for `darwin/arm64` and `darwin/amd64`.
- Default login shell is zsh; `/bin/bash` is 3.2. Scripts target POSIX `sh` or bash 3.2, or state that a newer bash is required (from Homebrew or Nix).
- BSD userland, not GNU (`sed -i ''`, `stat -f`, `date -j`): scripts follow the portable rules in `CONVENTIONS/CODE/SHELL.md`.
- Config and data: XDG paths with `~/.config` and `~/.local/share` fallbacks (`CONVENTIONS/INTERFACES/CONFIG.md`), not `~/Library/Application Support`; in Go, not `os.UserConfigDir()`.
- No systemd: launchd agents only when a daemon is required, else document running it by hand.
- Case-insensitive filesystem by default: never ship two paths that differ only by case.
- CI matrix: `CONVENTIONS/SYSTEMS/SUPPORT.md`.
