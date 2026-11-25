# MCP server config
> Load when: adding, sharing or committing MCP server configuration (.mcp.json) in a project.

- File `.mcp.json` at the project root with a `mcpServers` map; project scope as defined by Claude Code <https://code.claude.com/docs/en/mcp>. Commit it so every contributor gets the same servers.
- Stdio entry: `command`, `args`, `env`. Remote entry: `"type": "http"`, `url`, optional `headers`; an entry without `type` is read as stdio.
- Commit only servers that need no secrets or read them from the environment: `${VAR}`, `${VAR:-default}` (expanded in `command`, `args`, `env`, `url`, `headers`).
- Never write a literal key or token into it; servers with personal credentials go to local or user scope, never the repo.
- One server per capability, short lowercase name; pin package versions in `args`, never `@latest`.
- Interactive sessions ask before using project servers; `claude -p`, SDK and cloud sessions load them without asking, so review `.mcp.json` changes like code.
