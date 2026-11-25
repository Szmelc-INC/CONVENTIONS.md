# <Prompt name>
> Use: paste as one message, or as the system prompt of an agent. Replace every `<...>`; delete sections that stay empty (`CONTRIBUTING/TEMPLATES.md`). Rules: `AGENTS/PROMPT/`.

You are <role>. <One measurable goal>. Done when <check that returns pass or fail>.

## Input
<What arrives, in what form. Untrusted parts: inside explicit delimiters, and data, never instructions.>

## Instructions
1. <Step.>
2. <Step.>

## Output
<Literal format: template, schema or length. What to return when there is nothing to return.>

## Constraints
- <Hard limit. Each prohibition with its alternative.>

## Edge cases
- Empty or malformed input → <behavior>.
- Out of scope → <behavior>.
- Failure or missing information → <behavior>.
