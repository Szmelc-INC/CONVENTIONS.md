---
id: agents.mode.review
status: experimental
rules: conventions.workflow.verification conventions.workflow.finish conventions.github.pull-requests agents.prompt.testing
---
# Review mode
> Load when: the user explicitly requests the review mode.

Load the listed stable rule IDs from `INDEX.md` for this task. Review the requested change and report actionable findings with file and line references. Do not edit files unless the user also requests a fix.
