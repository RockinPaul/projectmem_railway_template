# projectmem Railway Template

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/projectmem?referralCode=YqmMB-&utm_medium=integration&utm_source=template&utm_campaign=generic)

Railway template for [projectmem](https://github.com/riponcm/projectmem), the open-source memory and judgment layer for AI coding agents. It runs projectmem's MCP server as a hosted service so agents that do not live on your laptop, such as cloud coding agents, CI bots, or a team sharing one memory, can log issues, attempts, fixes, and decisions and read them back.

It deploys one service, `projectmem`, from the Dockerfile in this repo, with a volume at `/data` for the memory files. There is no database and no LLM key: projectmem stores typed events as plain text and answers with deterministic lookups.

## What hosted projectmem is, and is not

projectmem is local-first by design, and upstream ships it as a stdio subprocess only. This template adds a small HTTP front (`serve.py`) so MCP clients can reach the same server over the network. What you get is the 17 MCP tools: `get_summary`, `get_issue`, `search_events`, `precheck_file`, `get_context`, `get_plan`, `log_issue`, `record_attempt`, `record_fix`, `add_decision`, `add_note`, and the rest.

What you do not get is everything that needs the real repository next to the server: git hooks and the pre-commit warning, the file watcher, `pjm wrap`, the dashboards, and git-history staleness checks. For a single developer on one machine, `pip install projectmem` is the better setup. Use this template when the agent and the memory cannot share a filesystem.

## Connect a client

Copy the service's public domain and the `MCP_TOKEN` variable. The endpoint is `https://<domain>/mcp` and every request needs `Authorization: Bearer <MCP_TOKEN>`.

Claude Code:

```
claude mcp add --transport http projectmem https://<domain>/mcp --header "Authorization: Bearer <MCP_TOKEN>"
```

OpenCode:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "projectmem": {
      "type": "remote",
      "url": "https://<domain>/mcp",
      "headers": { "Authorization": "Bearer <MCP_TOKEN>" }
    }
  }
}
```

Cursor and other clients that take a `url` plus `headers` object work the same way.

Treat the token like a password: anyone who has it can read and write your memory. Rotate it by changing `MCP_TOKEN` on the service, which redeploys in about a minute.

## Projects

`PROJECTMEM_PROJECTS` is a comma-separated list of project names (letters, digits, `-`, `_`). On every start the entrypoint creates any project that does not exist yet under `/data/projects/<name>`, initialises it with `pjm init`, and registers it. Existing projects are never touched. The first name becomes the active project, so tool calls that omit `project` land there; calls for any other project pass `project="<name>"`, and every write echoes the project it landed in.

To add a project later, append it to the variable and redeploy. To remove one from the registry, run `pjm project remove <name>` in the service shell; its files stay on the volume until you delete them.

## Variables

| Variable | Default | Purpose |
|---|---|---|
| `MCP_TOKEN` | generated | Bearer token required on `/mcp`. The server refuses to start without one. |
| `PROJECTMEM_PROJECTS` | `default` | Projects to create and register on start. |
| `PROJECTMEM_HOME` | `/data/home` | Registry and cross-project global memory. Keep it on the volume. |
| `PORT` | `8000` | Listening port; Railway routes the public domain to it. |
| `PROJECTMEM_NO_REDACT` | unset | Set to `1` to disable projectmem's secret redaction on logged text. Leave unset. |

## Data on the volume

```
/data/home/projects.json          registry
/data/home/global/                cross-project gotchas
/data/projects/<name>/.projectmem/events.jsonl   append-only event log
/data/projects/<name>/.projectmem/summary.md     distilled summary agents read
/data/projects/<name>/.projectmem/plan.md        intent file
```

Everything is plain text. Back up by downloading the volume or copying these files. Deleting the service deletes the volume.

## Upgrading projectmem

Bump `projectmem==` and `mcp==` in `Dockerfile` to the versions you want, together. Merging to `main` notifies everyone who deployed the template. Note breaking changes in `CHANGELOG.md`. `serve.py` uses two SDK entry points, `streamable_http_app` and `TransportSecuritySettings`; check both still exist before bumping `mcp` across a major version.

## Files

- `Dockerfile`: `python:3.12-slim` plus git and the pinned projectmem release
- `serve.py`: Streamable HTTP transport, `/health`, bearer auth, DNS-rebinding guard disabled for Railway's proxy
- `entrypoint.sh`: creates and registers projects from `PROJECTMEM_PROJECTS`, then starts `serve.py`
- `TEMPLATE_OVERVIEW.md`: the marketplace description
- `CHANGELOG.md`: what changed and how to upgrade an existing deployment
