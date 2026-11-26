---
id: conventions.workflow.finish
---
# Finish every change
> Load when: finishing a feature or fix, before calling work done.

- Done means everything the change touches is done; never leave half a feature for later.
- Carry it through the code, the `--help` text (global and per command) and the shell completions.
- Carry it through the docs (`README.md`, config comments, architecture contract) and packaging (`CONVENTIONS/PACKAGING/ARCH.md`, `CONVENTIONS/PACKAGING/NIX.md`).
- Version bump → every copy at once (`CONVENTIONS/GITHUB/RELEASES/VERSIONING.md`).
- Then verify on real data (`CONVENTIONS/WORKFLOW/VERIFICATION.md`) and get green CI before reporting (`CONVENTIONS/GITHUB/PULL-REQUESTS.md`).
