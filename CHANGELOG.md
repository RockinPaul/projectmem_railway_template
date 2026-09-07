# Changelog

## 2026-09 — initial release, projectmem 0.3.2

- One service built from `Dockerfile`: `python:3.12-slim`, git, `projectmem==0.3.2`, `mcp==2.2.0`.
- `serve.py` exposes the upstream MCP server over Streamable HTTP at `/mcp`, adds `/health`, requires `Authorization: Bearer <MCP_TOKEN>`, and disables the SDK's DNS-rebinding guard, which otherwise answers 421 behind Railway's proxy.
- `entrypoint.sh` creates and registers the projects listed in `PROJECTMEM_PROJECTS` under `/data/projects/<name>` and makes the first one active.
- Volume at `/data`; `PROJECTMEM_HOME=/data/home`.

### Upgrading an existing deployment

projectmem's event schema is plain JSON lines and has been stable since 0.1; upstream migrates its registry file in place and keeps a `.bak`. Applying a template update redeploys the service with the new pins and never touches the volume. Check `/health` afterwards; it reports the running projectmem version.
