# Prompts
> Load when: asking an agent to use, apply, extend or maintain the conventions, or looking for a ready prompt to paste.

Paste one prompt into any agent with file access; each is self-contained. Bare rule paths resolve against the conventions root (install: `~/.config/szmelc/conventions`), as `SKILL.md` states. Replace `{...}`. Writing your own: `AGENTS/PROMPT/`.

## Use
| Task | Prompt |
|---|---|
| Install or update | Clone or pull `https://github.com/Szmelc-INC/CONVENTIONS.md` into `~/.config/szmelc/conventions`, run its `install.sh status`, then `install.sh`; report what was linked. |
| Look up a rule | Read `~/.config/szmelc/conventions/INDEX.md`, load only the files whose trigger matches {topic}, and answer with rule lines and their paths. |

## Apply to a project
| Task | Prompt |
|---|---|
| Adopt | Follow `~/.config/szmelc/conventions/SKILL.md`. Run `~/.config/szmelc/conventions/install.sh project .`, fill `AGENTS.md` with this repo's real commands, layout and gotchas only. |
| Audit | Follow `~/.config/szmelc/conventions/SKILL.md`. Audit this repo against every rule whose trigger applies; list gaps as path, rule, fix. Change nothing. |
| Fix gaps | Follow `~/.config/szmelc/conventions/SKILL.md`. Fix the gaps from the audit, one topic per branch and PR per `CONVENTIONS/WORKFLOW/BRANCHES.md`. |
| Agent file | Follow `~/.config/szmelc/conventions/SKILL.md` and `CONVENTIONS/SPECS/THIRD-PARTY/AGENTS-MD.md`. Write or tighten this repo's `AGENTS.md`; never restate global rules. |
| GitHub conformance | Follow `~/.config/szmelc/conventions/SKILL.md`. Make README, metadata, labels, rulesets, workflows and Pages conform to `CONVENTIONS/GITHUB/` and `CONVENTIONS/SPECS/THIRD-PARTY/README-MD.md`; show the diff before applying settings. |
| Port | Follow `~/.config/szmelc/conventions/SKILL.md` and `CONVENTIONS/SYSTEMS/SUPPORT.md`. Port this project to {Arch/Nix/WSL2/macOS}; list what changes before editing. |
| Skill | Follow `~/.config/szmelc/conventions/SKILL.md` and `CONVENTIONS/SPECS/THIRD-PARTY/SKILL-MD.md`. Write a `SKILL.md` for {task} from `TEMPLATES/SKILL.md`. |
| Review a PR | Follow `~/.config/szmelc/conventions/SKILL.md`. Review PR {n} against the rules whose triggers match its diff; report violations with rule paths. |

## Extend (in a clone of the conventions repo)
| Task | Prompt |
|---|---|
| Add a rule | Follow `CONTRIBUTING/WRITING.md`. Add a rule about {X}: grep for an owner first, then edit or create the file, build, check, PR. |
| Propose | Follow `CONTRIBUTING/LIFECYCLE.md`. Draft {X} as an experimental convention on an `experimental/*` branch, build, check, PR. |
| Promote or demote | Follow `CONTRIBUTING/LIFECYCLE.md`. {Promote/demote} `{path}`; fix every reference, build, check, PR. |
| Restructure | Follow `CONTRIBUTING/WRITING.md` and `CONVENTIONS/SPECS/ORIGINAL/CORE-MAPS.md`. {Split/merge/rename} category {X}; update tables and references; flag it as major. |
| New output format | Follow `CONTRIBUTING/INDEXING.md`. Add a generated {format} output to the build, list it as generated, build, check, PR. |

## Maintain
| Task | Prompt |
|---|---|
| Release | Follow `CONTRIBUTING/VERSIONING.md`. Pick the bump from merged PRs since the last tag, then tag and release with the bundle assets. |
| Pin | Follow `CONTRIBUTING/VERSIONING.md`. Pin my install at `~/.config/szmelc/conventions` to {vX.Y.Z} (or back to `main`) and re-run the installer. |
| Own fork | Follow `CONTRIBUTING/DIY.md`. Turn this clone into conventions for {team}: rename the skill and URLs, keep the pipeline, build, check. |
| Sync fork | Follow `CONTRIBUTING/DIY.md`. Merge upstream `main` into this fork on a `chore/*` branch, resolve conflicts keeping local rules, build, check, PR. |
