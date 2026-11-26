---
id: conventions.systems.windows-wsl2
---
# Windows via WSL2
> Load when: supporting Windows users or testing a tool under WSL2.

- Windows support means WSL2; Arch on WSL preferred (`wsl --install archlinux`), any distro works via Nix (`CONVENTIONS/SYSTEMS/NIX.md`).
- Inside WSL the tool is a Linux tool: same packages, paths and rules as `CONVENTIONS/SYSTEMS/ARCH.md`.
- Keep repos and state on the Linux filesystem (`~/`), never under `/mnt/c` (slow I/O, permission and case issues).
- LF line endings everywhere (`CONVENTIONS/FORMATS/EDITORCONFIG.md`).
- No hard dependency on systemd: check for it and degrade with a clear message.
- Native Windows only where the tool needs it: a Go `windows/amd64` release artifact, best effort, untested unless CI says so.
- PowerShell or `.cmd` scripts only as thin wrappers that call the real tool; logic stays in Go or shell.
