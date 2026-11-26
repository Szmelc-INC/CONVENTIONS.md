# Awesome list
> Load when: creating, editing or submitting an awesome list (`awesome-<topic>` repo).

- Standard: <https://github.com/sindresorhus/awesome/blob/main/awesome.md>; submission checklist: its `pull_request_template.md`.
- Repo name lowercase slug `awesome-<topic>`; default branch `main`; topics `awesome` and `awesome-list` (`CONVENTIONS/GITHUB/REPO/METADATA.md`).
- Heading title case `# Awesome <Topic>`, awesome badge to its right: `[![Awesome](https://awesome.re/badge.svg)](https://awesome.re)` (the one non-Shields.io badge).
- Under the heading: one short description of the topic, not of the list.
- `## Contents` is the first section; one nesting level at most; never lists `Contributing` or `Footnotes`.
- Entry: `- [Name](url) - Description.`; description starts uppercase, ends with a period; no unmaintained, archived or deprecated items.
- Only the best items; curation, not everything.
- `contributing.md` in the root; optional `Contributing` section at the top or bottom; extra notices in a `Footnotes` section at the bottom.
- License: CC0 1.0 (any Creative Commons license accepted; code licenses rejected) in a root `license` file; no license section in the readme. Overrides MIT.
- Overrides the README section order of `CONVENTIONS/SPECS/THIRD-PARTY/README-MD.md`.
- Lint: `npx awesome-lint` clean before every push.
- Upstream submission: list at least 30 days old, not AI-generated.
