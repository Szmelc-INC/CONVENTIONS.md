# SZMELC
> Load when: asked about Szmelc itself, its public organisations and projects, the ecosystem, or the projects index.

Szmelc: the public organisations and projects these conventions serve. Only public material lives here.

## Organisations
Indexed on the site's Projects tab from `SZMELC/sources.conf` (GitHub API, public, non-archived, non-fork repos only).

| Owner | Kind |
|---|---|
| [Szmelc-INC](https://github.com/Szmelc-INC) | Organisation; home of this repo |
| [CYBERSZP0NT](https://github.com/CYBERSZP0NT) | Organisation; AI-focused projects |
| [Entropy-Linux](https://github.com/Entropy-Linux) | Organisation; v0-era sister project |
| [sernik77](https://github.com/sernik77) | User |

## Sites
- <https://szmelc.com/> — Szmelc home.
- <https://szmelc-inc.github.io/CONVENTIONS.md/> — this repo, browsable, with the projects index.
- <https://szmelc-inc.github.io/SAUR/> — SAUR, the signed pacman repository of Szmelc software (`[saur]` stable, `[saur-ex]` experimental).

## Principles
The Szmelc DNA: every era keeps these.
- No bloat: single binaries, stdlib first, the simplest thing that works (`CONVENTIONS/code/stack.md`). Motto: *NIE TOLERUJEMY BLOATU*.
- Portable and removable: one prefix, reversible install, user layer untouched by upgrades (`CONVENTIONS/packaging/install.md`).
- One command: every project has one entry point with subcommands (`CONVENTIONS/interfaces/cli.md`).
- Modular by default: features are files you add, toggle and delete (`CONVENTIONS/repo/layout.md`).
- Linux first: Arch is the reference platform, Nix second; every tool ships a `PKGBUILD` and a `flake.nix` (`CONVENTIONS/packaging/`).
- Humor on top, rigor underneath: ™ and memes in the lore, signed packages and honest risk notes in the engineering (`CONVENTIONS/repo/writing.md`).
- Free software: MIT by default; forks labeled independent and unaffiliated (`CONVENTIONS/repo/metadata.md`).
- One identity: shared colors and CLI/TUI style (`CONVENTIONS/design/colors.md`, `CONVENTIONS/interfaces/`).
- Humans and agents follow the same rules; agents load them lazily (`AGENTS/README.md`).

## Eras
Ecosystem generations; independent of project versions (`CONVENTIONS/workflow/releases.md`).

| Era | Name | When | Defining idea |
|---|---|---|---|
| v0 | GNU-Szmelc | 2023 | One Bash suite in one folder, removable with one command; sister project Entropy Linux |
| v1 | Szmelc | 2024 – mid 2026 | Many small tools, scripts and configs; README-driven; source material for later eras |
| v1.9 | Modern Szmelc | Aug – Nov 2026 | Agent-built, packaged, signed, documented contracts (SAUR, SilkRouter, Modern-Shell); the base of the stable rules here |
| v2 | Kombinat | Nov 2026 → | One core, one API, everything a module; v1.9 habits made law |
| v3 | Logos | future | One universal format for everything; not designed yet |

- Porting a v1 project means meeting the stable rules, not rewriting it in one go.
- Ideas for later eras go to `CONVENTIONS/experimental/` via `experimental/*` branches, never straight into stable rules.

## Projects index
- Sources: `SZMELC/sources.conf` (`owner <login>`, `ignore <name|owner/name>`).
- Built by `META/tools/site.sh` in CI, refreshed nightly; private, archived and forked repos are never listed.
- Add an owner only when its account and repos are public.
