# Security policy
> Load when: creating or editing SECURITY.md, or setting up vulnerability reporting.

- GitHub community health file <https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository>: `SECURITY.md` in the root, `.github/` or `docs/`; org default in the org `.github` repo (`CONVENTIONS/GITHUB/ORGANIZATIONS.md`).
- `## Supported versions`: table of version ranges and whether they get fixes; usually the latest release only.
- `## Reporting a vulnerability`: GitHub private vulnerability reporting (Security tab → Report a vulnerability); enable it per `CONVENTIONS/GITHUB/CODE-SECURITY.md`.
- Never ask for vulnerability reports in public issues, discussions or chat.
- Response expectations with numbers: acknowledgement time, status updates, target fix time; reporter credited in the advisory unless they decline.
- Fix in the advisory's temporary private fork; publish the advisory with the patch release (`CONVENTIONS/GITHUB/RELEASES/TAGS.md`).
- No personal email addresses; any other private channel belongs to the project or org.
