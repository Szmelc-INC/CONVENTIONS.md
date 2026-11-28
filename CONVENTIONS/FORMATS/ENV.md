---
id: conventions.formats.env
---
# .env files
> Load when: adding a `.env` file, `.env.example`, or env-file loading to a project.

- `.env` is gitignored and never committed (`CONVENTIONS/GITHUB/CODE-SECURITY.md`).
- Commit `.env.example`: every key the tool reads, placeholder or empty values, a comment per key.
- Keys `UPPER_SNAKE` with the tool prefix (`CONVENTIONS/CODE/NAMING.md`).
- One `KEY=value` per line: no spaces around `=`, no `export`, quote values containing spaces.
- Optional: the tool runs without it; env vars keep their place in config precedence (`CONVENTIONS/INTERFACES/CONFIG.md`).

## Minimal example

A comment per key; the value with spaces is quoted; the values are placeholders, never real credentials.

```sh
# Port the dashboard listens on
DASHBOARD_PORT=8080
# Directory for dashboard state; quotes because of the space
DASHBOARD_DATA_DIR="/var/lib/example data"
```
