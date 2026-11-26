---
id: conventions.systems.support
---
# Platform support
> Load when: deciding which operating systems a tool supports, writing platform notes in a README, or setting up a CI test matrix.

- Support order: Arch > Nix (NixOS, or Nix on any distro) > Windows via WSL2 > macOS > other Linux and BSD (best effort).
- When targets conflict, the higher one wins; never degrade Arch to help a lower target.
- POSIX first: portable shell and paths (`CONVENTIONS/CODE/SHELL.md`), XDG dirs (`CONVENTIONS/INTERFACES/CONFIG.md`).
- Supported = CI-tested: the target's build and tests run in `check.yml` (`CONVENTIONS/GITHUB/ACTIONS/CI.md`). Anything else is best effort.
- WSL2 counts as covered by the Linux CI jobs; no separate Windows runner.
- Add `macos-latest` to the test matrix next to `ubuntu-latest` only when the tool claims macOS support.
- README states supported and best-effort platforms in one line (`CONVENTIONS/SPECS/THIRD-PARTY/README-MD.md`).
- Per platform: `CONVENTIONS/SYSTEMS/ARCH.md`, `CONVENTIONS/SYSTEMS/NIX.md`, `CONVENTIONS/SYSTEMS/WINDOWS-WSL2.md`, `CONVENTIONS/SYSTEMS/MACOS.md`, `CONVENTIONS/SYSTEMS/LINUX.md`.
