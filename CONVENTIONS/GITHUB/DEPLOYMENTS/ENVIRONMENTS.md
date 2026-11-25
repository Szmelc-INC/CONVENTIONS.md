# Deployment environments
> Load when: deploying anything from Actions, or adding deployment secrets.

- Every deploy job declares `environment:` with `name` (`github-pages`, `production`) and `url` from the deploy step's output.
- Deployment branches: `main` only (tags `v*` for release deploys).
- Secrets used only by one deploy are environment secrets, not repo secrets.
- Required reviewers or wait timers only when a second human can approve; solo repos rely on the branch policy.
- GitHub Free: environment secrets and branch policies work in public repos only; private repos use repo secrets and deploy only from `main`.
