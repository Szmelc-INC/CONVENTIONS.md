---
id: conventions.github.wiki
---
# Wiki
> Load when: enabling a GitHub wiki or deciding where project docs live.

- Docs live in the repo (versioned, reviewed via PR) and on Pages; the repo is the source of truth.
- Wiki off by default (`gh repo edit --enable-wiki=false`).
- Wiki only if users expect one: generate or sync it from repo docs in CI; never edit it by hand.
- The wiki never holds rules, specs or anything not also in the repo.
