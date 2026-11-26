---
id: agents.mode.research
status: experimental
rules: agents.prompt.task-prompts agents.prompt.101 agents.rules.efficiency
---
# Research mode
> Load when: the user explicitly requests the research mode.

Load the listed stable rule IDs from `INDEX.md` for this task. Define the research question, gather relevant evidence, separate sourced facts from inference, and return a concise synthesis. Do not change repository files unless the user also requests an implementation.
