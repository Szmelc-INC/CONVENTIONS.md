# Naming
> Load when: naming a repo, binary, package, env var, config key, file or doc.

| Thing | Convention | Example |
|---|---|---|
| Repo | `Title-Case-With-Hyphens` | `Modern-Shell`, `Linux-From-Something` |
| Binary / command | lowercase, short, one word | `msh`, `saur`, `lfn` |
| Command alias | same binary, dispatched on `argv[0]` | `px` → `silkrouter` |
| Env var | `UPPER_SNAKE` with the tool prefix | `SAUR_COLOR` |
| Config key | `snake_case`, English, never translated | `build_timeout` |
| Shell function / exported var | `snake_case` / `UPPER_SNAKE` | `build_pkg`, `SAUR_OUT` |
| Experimental package | `<name>-ex` | `saur-ex` |
| Major-version contract | `ARCHITECTURE-v<N>.md` | `ARCHITECTURE-v4.md` |
| Branch | `CONVENTIONS/workflow/branches.md` | `feat/signing` |

- Names say what a user gets, not how it is built.
- No version numbers in repo or binary names; versions live in tags (`CONVENTIONS/workflow/releases.md`).
