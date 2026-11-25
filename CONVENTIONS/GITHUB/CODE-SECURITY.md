# Code security
> Load when: creating a repo, adding dependencies, or handling Dependabot, secret-scanning or code-scanning alerts.

- Dependabot alerts and security updates on for every repo.
- `.github/dependabot.yml`: version updates for `github-actions` plus each package ecosystem, `interval: weekly`, `groups:` to batch minor/patch.
- Dependabot PRs follow the normal PR flow; merge when CI is green, never skip checks.
- Secret scanning + push protection on (`gh repo edit --enable-secret-scanning --enable-secret-scanning-push-protection`; free for public repos).
- Leaked secret: rotate it first, then remove it; history rewriting needs owner approval.
- CodeQL default setup for supported languages (free for public repos); fix or dismiss alerts with a reason.
- Private vulnerability reporting on for public repos.
- Never commit secrets, tokens or `.env` files; CI reads them from Actions secrets.
