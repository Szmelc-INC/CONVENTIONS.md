---
id: conventions.formats.markdown.tables
---
# Markdown tables
> Load when: adding a table to a Markdown file.

- Table only for 3+ parallel attributes per row; otherwise a list.
- Header row plus `|---|` separator; first column is the key.
- Escape a literal pipe in a cell as `\|`.
- Short cells: a value or phrase, no paragraphs or lists; link out for detail.
- No merged or empty structural cells; one fact per cell.
- Wide tables are fine: GitHub scrolls them horizontally; never split one table into several to fit.

## Escaped pipe

The pipe inside the code span is escaped, so the row keeps its two cells:

```markdown
| Command | Purpose |
|---|---|
| `grep ERROR app.log \| wc -l` | count matching lines |
```
