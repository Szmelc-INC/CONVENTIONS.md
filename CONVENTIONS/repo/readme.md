# README
> Load when: writing or editing a project README.

- English. Truthful: every feature and dependency listed exists; update it in the same change as the code.
- Top: `# Name`, one bold sentence saying what it is, the one-line install, badges (`CONVENTIONS/design/colors.md`).
- Then, skipping empty ones: Usage, How it works, Configuration, Packaging, License.
- Install: package first (SAUR `pacman -S`, `nix run`); never distro-by-distro package-manager blocks; elevation via `pkexec`.
- No `curl … | bash` from a branch tip; point at a tag or a signed script.
- State limits, risks and trust boundaries plainly: what leaves the machine, who can reach a key.
- Plain headings for structure; no blockquote-as-heading, no `\` line breaks, no version in the title.
- Polish readers → separate `README-PL.md`; one language per file (`CONVENTIONS/repo/writing.md`).
- Remove agent leftovers ("CONSOLIDATED DELIVERABLE", "Here is…", "As an AI…") before committing.
