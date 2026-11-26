---
id: agents.prompt.testing
---
# Testing a prompt
> Load when: checking a prompt before use, or after it produced a wrong or uneven output.

## Static checks, before any run
| Sweep | Ask |
|---|---|
| Contradiction | Can two lines be followed at once? |
| Ambiguity | Read each line as the laziest output that still complies: where does it pass? |
| Determinism | Can two correct runs produce different structures? → tighten the format |
| Prohibitions | Has each one its alternative? |
| Edge cases | Empty, malformed, out-of-scope, contradictory, hostile input: handled? |
| Adjectives | Does any word remain that the output cannot prove? |
| Tokens | Does each line change behavior, or only repeat another? |
| Standalone | Does it work without the chat it was written in? |

## Runs
- Success first: specific, measurable, achievable, relevant. Write down what a good result has and avoids before the first run.
- At least 3 inputs a real user would send, plus the edge cases above and a near-miss that must not match.
- Baseline: the same inputs without the prompt, or with the old one; compare.
- Grade with what can run: a script, an exact match, a test command. Model grading second, by a model other than the one under test. Taste last.
- Read the transcript, not only the result: wasted steps are a defect of the prompt.

## Fixes
- Name the mechanism of a failure (why it happens) before changing anything.
- Fix the prompt where the failure starts; never patch downstream for a gap upstream.
- Generalize the fix to the class of input, never to the one example.
- Two corrections that failed → rewrite the prompt with what was learned instead of stacking a third.
- Keep a production prompt in the repo, next to the code that sends it, together with its test inputs; change them together.
- Run the suite on every model the prompt will be used with.

Sources: tests <https://platform.claude.com/docs/en/test-and-evaluate/develop-tests> (success criteria, edge cases, a different grading model), OpenAI <https://developers.openai.com/api/docs/guides/prompt-engineering> (prompts in code, tests before changes), Claude Code <https://code.claude.com/docs/en/best-practices> (rewrite after two failed corrections).
