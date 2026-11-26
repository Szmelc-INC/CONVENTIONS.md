# Security policy

This repo ships documentation plus shell tooling (`install.sh`, `META/tools/`). Relevant issues: the installer or tools writing outside their target, unsafe shell handling, a rule that tells agents to do something unsafe, or a leaked secret.

## Supported versions

| Version | Fixes |
|---|---|
| `main` and the latest release | Yes |
| Older releases | No; upgrade or re-pin |

## Reporting a vulnerability

- Report privately: Security tab → **Report a vulnerability** (<https://github.com/Szmelc-INC/CONVENTIONS.md/security/advisories/new>).
- Never in public issues, discussions or chat.
- Acknowledgement within 7 days, status updates at least every 14 days, target fix within 30 days.
- The maintainer develops the fix in the advisory's private fork and publishes it with the patch release. The advisory credits reporters unless they decline.
