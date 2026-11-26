---
id: conventions.systems.linux
---
# Other Linux distros
> Load when: supporting or documenting install on Debian, Ubuntu, Fedora or another non-Arch, non-NixOS distro.

- Best effort; install via Nix (`CONVENTIONS/SYSTEMS/NIX.md`) or a static binary from a release (`CONVENTIONS/GITHUB/RELEASES/AUTOMATION.md`).
- No distro-by-distro package blocks in docs (`CONVENTIONS/SPECS/THIRD-PARTY/README-MD.md`).
- Go binaries: `CGO_ENABLED=0` static builds for `linux/amd64` and `linux/arm64`, so no glibc version ties.
- Scripts: portable shell rules in `CONVENTIONS/CODE/SHELL.md`; no reliance on distro-specific paths or package managers.
- Root: `{{profile.privilege_tool}}` where supported; otherwise name the command the user must run as root.
