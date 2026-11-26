---
id: agents.mode.release
status: experimental
rules: conventions.workflow.branches conventions.github.releases.versioning conventions.github.releases.tags conventions.github.releases.automation conventions.workflow.finish
---
# Release mode
> Load when: the user explicitly requests the release mode.

Load the listed stable rule IDs from `INDEX.md` for this task. Check release readiness, version and tag policy, automation, and release assets. Stop before publishing unless the user has authorized the release.
