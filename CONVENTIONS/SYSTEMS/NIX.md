# Nix and NixOS
> Load when: targeting NixOS, Nix on another OS, or nix-darwin.

- Flake with package, app and devShell (`CONVENTIONS/PACKAGING/NIX.md`); `nix run github:<org>/<repo>` is the zero-install path.
- Same flake serves NixOS, Nix on any Linux distro, and macOS (with or without nix-darwin).
- NixOS or home-manager module: optional, only when the tool has a service or config worth declaring.
- `/nix/store` is read-only: write state only to XDG dirs (`CONVENTIONS/INTERFACES/CONFIG.md`).
- No FHS assumptions: on NixOS only `/usr/bin/env` and `/bin/sh` exist; find binaries via `PATH` (`CONVENTIONS/CODE/SHELL.md`).
- No self-updaters or runtime downloads of binaries; updates come from the flake.
