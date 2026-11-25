# SZMELC
> Load when: asked about Szmelc itself, its public organisations and projects, the ecosystem, or the projects index.

Szmelc: the public organisations and projects these conventions serve. Only public material lives here.

## Organisations
Indexed on the site's Projects tab from `SZMELC/sources.conf` (GitHub API, public, non-archived, non-fork repos only).

| Owner | Kind |
|---|---|
| [Szmelc-INC](https://github.com/Szmelc-INC) | Organisation; home of this repo |
| [CYBERSZP0NT](https://github.com/CYBERSZP0NT) | Organisation |
| [Entropy-Linux](https://github.com/Entropy-Linux) | Organisation |
| [sernik77](https://github.com/sernik77) | User |

## Sites
- <https://szmelc.com/> — Szmelc home.
- <https://szmelc-inc.github.io/CONVENTIONS.md/> — this repo, browsable, with the projects index.
- <https://szmelc-inc.github.io/SAUR/> — SAUR, the signed pacman repository of Szmelc software (`[saur]` stable, `[saur-ex]` experimental).

## Principles
- Anti-bloat: minimal dependencies, stdlib first, the simplest thing that works (`CONVENTIONS/code/stack.md`).
- Portable and packaged: every tool ships an Arch `PKGBUILD` and a `flake.nix` (`CONVENTIONS/packaging/`).
- One identity: shared colors and CLI/TUI style across projects (`CONVENTIONS/design/colors.md`, `CONVENTIONS/interfaces/`).
- Humans and agents follow the same rules; agents load them lazily (`AGENTS/README.md`).

## Projects index
- Sources: `SZMELC/sources.conf` (`owner <login>`, `ignore <name|owner/name>`).
- Built by `META/tools/site.sh` in CI, refreshed nightly; private, archived and forked repos are never listed.
- Add an owner only when its account and repos are public.
