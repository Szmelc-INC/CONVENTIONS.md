---
id: conventions.github.deployments.github-pages
---
# GitHub Pages
> Load when: publishing a site, docs or web UI on GitHub Pages.

- Source "GitHub Actions" (`gh api -X POST repos/<owner>/<repo>/pages -f build_type=workflow`); never a `gh-pages` branch.
- Build job → `actions/upload-pages-artifact`; deploy job → `actions/deploy-pages` with `pages: write`, `id-token: write`, environment `github-pages` (`CONVENTIONS/GITHUB/DEPLOYMENTS/ENVIRONMENTS.md`).
- Never commit build output; the output dir (`public/`) is gitignored.
- Build script lives in the repo and gives the same result locally; the workflow only calls it.
- Output: one self-contained `index.html` (CSS, JS, data inlined) that works offline and over `file://`.
- Next to it: the same data as JSON; docs sites also ship `llms.txt` (`CONVENTIONS/SPECS/THIRD-PARTY/LLMS-TXT.md`).
- Deploy only from `main`; triggers: push on source paths, `workflow_dispatch`, `repository_dispatch` for refreshes from other repos.
- Nightly `schedule` only when data comes from outside the repo (`CONVENTIONS/GITHUB/ACTIONS/WORKFLOWS.md`).
- Repo homepage = the Pages URL unless a real site exists (`CONVENTIONS/GITHUB/REPO/METADATA.md`).
- Custom domain only when one is owned: set it in Pages settings (`gh api -X PUT repos/<owner>/<repo>/pages -f cname=<domain>`); Actions deploys ignore a `CNAME` file.
- Look and layout: `CONVENTIONS/INTERFACES/WEBUI/THEME.md` and `CONVENTIONS/INTERFACES/WEBUI/LAYOUT.md`.
