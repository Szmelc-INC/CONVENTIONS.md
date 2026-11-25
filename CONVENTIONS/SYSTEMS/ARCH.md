# Arch Linux
> Load when: targeting, installing on, or integrating a tool with Arch Linux.

- Primary target: everything works here first.
- Install path: `pacman -S` from SAUR, built from the project's `PKGBUILD` (`CONVENTIONS/PACKAGING/ARCH.md`).
- Rolling release: depend on current package versions; never pin or vendor old libraries.
- Daemons: systemd user units, shipped in `/usr/lib/systemd/user/` by the package, never system units for per-user work.
- Paths: XDG dirs (`CONVENTIONS/INTERFACES/CONFIG.md`); never write outside the package's files and the user's XDG dirs.
- Root: `pkexec` for the one step that needs it (`CONVENTIONS/CODE/SHELL.md`).
