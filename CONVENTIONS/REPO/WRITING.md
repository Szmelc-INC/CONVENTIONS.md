---
id: conventions.repo.writing
---
# Writing & voice
> Load when: writing docs, help text, error messages, commit messages, or community and lore text.

- English for everything structural: code, identifiers, comments, docs, config keys, commits, logs.
- Use the profile's cultural language for `README-<locale>.md`, community posts and lore. One language per file.
- Never translate machine-parsed identifiers (commands, config keys, schema fields, event names).
- Docs voice: plain, honest, specific, second person. Name limits and risks. No filler adjectives ("modern", "clean", "powerful", "seamless") and no claim words ("production-ready", "battle-tested", "comprehensive"): state the count, test or platform instead. Profile and examples: `AGENTS/PROMPT/DOCS-VOICE.md`.
- No bold lead-ins on list items; put the identifier in backticks.
- Humor (™, memes, lore) lives in profiles, banners and lore docs; never in specs, error messages or identifiers.
- `™` and other marks never appear in identifiers, package names or config.
- Dense: cut every word that does not change the meaning. Rules are imperative one-liners.
- Prose structure (sentences, procedures, errors, hedges): `CONVENTIONS/REPO/STE100PP.md`.
