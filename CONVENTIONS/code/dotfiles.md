# Shell environment & dotfiles
> Load when: building or changing a shell setup: rc files, dotfiles, plugins, prompt, shell integrations.

- The rc file is a loader only: it bootstraps and sources; real config lives in one directory (e.g. `~/.zsh/`) under git.
- Runcommands are `NN-name.zsh`, sourced in lexical order; the number encodes load order; leave gaps (00, 10, 20…).
- One concern per file; line 1 is `# NN-name.zsh — <concern>`.
- Every file is re-sourceable; guard anything order-sensitive.
- Functions: one per file, file name == function name (autoload); completions `_name`; scripts in `bin/` executable with a shebang.
- Plugins are declared in the plugin manager, never hand-cloned.
- One idempotent bootstrap brings a bare shell to the full setup; a manual step is a bug.
- Machine-local overrides and secrets in a gitignored `local/` directory, sourced last.
- Installers snapshot before changing a live setup; a user layer is never touched by upgrades.
- Baseline output: syntax highlighting, colored aligned listings, pickers with a live preview.
- Reference implementations: Silver-ZSH (`SHELL-INTEGRATION-BIBLE.md`), Modern-Shell.
