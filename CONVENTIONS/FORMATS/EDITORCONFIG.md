# EditorConfig & line endings
> Load when: creating a repo, or adding `.editorconfig` or `.gitattributes`.

- `.editorconfig` at the repo root with `root = true`.
- `[*]`: `charset = utf-8`, `end_of_line = lf`, `insert_final_newline = true`, `trim_trailing_whitespace = true` (Markdown included: no trailing-space breaks, `CONVENTIONS/FORMATS/MARKDOWN/STYLE.md`).
- Indent per language: 2 spaces default; tabs for Go and `Makefile`; 4 spaces where the language standard says so (Python).
- `.gitattributes` first line `* text=auto eol=lf`; mark binaries (`*.png binary`).
- Never commit CRLF; Windows editors and WSL checkouts follow these files (`CONVENTIONS/SYSTEMS/WINDOWS-WSL2.md`).
