---
id: agents.prompt.classes
---
# Prompt classes
> Load when: deciding which sections a prompt needs, or combining two kinds of work in one prompt.

## Every prompt
Role and objective; ordered instructions; the literal output format; edge cases and fallbacks (empty, malformed, out-of-scope, contradictory input).

## By class
| Class | Add |
|---|---|
| Extractor, classifier | Closed label set with the boundary of each label; one worked example and one near-miss; an explicit `unknown`; behavior when several labels match |
| Agent, tool user | `AGENTS/PROMPT/AGENT-PROMPTS.md` |
| Generator, creative | Voice by constraint (sentence length, vocabulary, forbidden constructions), never by adjective; a length target; one or two exemplars |
| Transformer, rewriter | Invariants that must survive (facts, identifiers, language); what may be dropped |
| Judge, evaluator | A rubric with a scale and an anchor per dimension; a tie-break; a verdict only with evidence from the input; permission to return `No findings.` |
| Persona, conversation | Register; refusal and out-of-scope handling; assumptions about state and memory; when to escalate to a human |

## Only when triggered
- Context: only if the role and the instructions do not already imply it.
- Reasoning procedure: only for dependent sub-decisions; say what to weigh, not that the model should think.
- Untrusted input handling: mandatory when the target reads third-party content (`AGENTS/PROMPT/WRITING.md`).
- Examples: whenever a boundary is subtle.

## Two classes in one prompt
1. Name the primary class: the one that produces the main deliverable.
2. Take the additions of both; where they overlap keep the stricter; where they conflict the primary class wins.
3. Order the sections by the primary class's execution flow and fold the others in where they fire. Never two parallel section sets.
