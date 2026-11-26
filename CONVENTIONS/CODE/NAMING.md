# Naming
> Load when: naming a repo, binary, package, env var, config key, file or doc.

| Thing | Convention | Example |
|---|---|---|
| Repo | `Title-Case-With-Hyphens` | `Modern-Shell`, `Linux-From-Something` |
| Binary / command | lowercase, short, one word | `msh`, `tool`, `lfn` |
| Command alias | same binary, dispatched on `argv[0]` | `px` → `silkrouter` |
| Env var | `UPPER_SNAKE` with the tool prefix | `TOOL_COLOR` |
| Config key | `snake_case`, English, never translated | `build_timeout` |
| Shell function / exported var | `snake_case` / `UPPER_SNAKE` | `build_pkg`, `TOOL_OUT` |
| Experimental package | `<name>-ex` | `tool-ex` |
| Major-version contract | `ARCHITECTURE-v<N>.md` | `ARCHITECTURE-v4.md` |
| Branch | `CONVENTIONS/WORKFLOW/BRANCHES.md` | `feat/signing` |

- Names say what a user gets, not how it is built.
- No version numbers in repo or binary names; versions live in tags (`CONVENTIONS/GITHUB/RELEASES/VERSIONING.md`).
