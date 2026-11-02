# Deploy and Host projectmem on Railway

projectmem is the open-source memory and judgment layer for AI coding agents. It records what happened while building a project as typed events, issues, attempts, fixes, decisions and notes, and feeds that history back to the agent through a native MCP server, so the agent stops repeating approaches that already failed. This template runs projectmem 0.3.4 as a hosted MCP server with a persistent volume, for agents that do not share a filesystem with you.

## About Hosting projectmem

Hosting projectmem on Railway means one small service and one volume. The service runs upstream projectmem from PyPI behind a thin HTTP front that exposes the MCP server over Streamable HTTP at `/mcp`, protected by a bearer token generated at deploy time. Memory lives as plain text files on the volume: an append-only event log, a distilled summary, and a plan file per project, plus a registry and cross-project gotchas. There is no database, no LLM key, and no telemetry; projectmem answers with deterministic lookups. On every start the service creates and registers the projects you name in a variable, so adding a project is a one-line change.

## Common Use Cases

- Shared project memory for cloud coding agents and CI bots that cannot run projectmem locally
- One memory server for a team, so every agent session starts from what the last one learned
- A remote judgment layer that warns an agent before it retries a fix that already failed

## Dependencies for projectmem Hosting

- A Railway account
- An MCP client that supports remote HTTP servers with custom headers, such as Claude Code, OpenCode, or Cursor

### Deployment Dependencies

- projectmem upstream repository: https://github.com/riponcm/projectmem
- projectmem on PyPI: https://pypi.org/project/projectmem/
- Template repository: https://github.com/RockinPaul/projectmem_railway_template

### Implementation Details

- `projectmem`: built from the template repo's Dockerfile (`python:3.12-slim`, git, `projectmem==0.3.4`), healthcheck `/health`, public domain, volume at `/data`.
- Endpoint: `https://YOUR-DOMAIN/mcp` with header `Authorization: Bearer YOUR-MCP-TOKEN`. Claude Code: `claude mcp add --transport http projectmem https://YOUR-DOMAIN/mcp --header "Authorization: Bearer YOUR-MCP-TOKEN"`.
- `PROJECTMEM_PROJECTS` lists the projects to create (default `default`). Tool calls name their project with `project="PROJECT-NAME"`; the first project is the active one for calls that omit it.

Hosted projectmem exposes the MCP tools only. Git hooks, the pre-commit warning, the file watcher, and the dashboards need the repository on the same machine and stay with the local `pip install projectmem`.

## Why Deploy projectmem on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying projectmem on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
