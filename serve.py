"""Serve projectmem's MCP server over Streamable HTTP.

Upstream ships the server as a stdio subprocess only. This wraps the same
server object for Railway: HTTP transport on $PORT, a /health route for the
healthcheck, and a static bearer token because the endpoint is public.
"""
import os
import sys

import uvicorn
from mcp.server.transport_security import TransportSecuritySettings
from starlette.applications import Starlette
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse, PlainTextResponse
from starlette.routing import Mount, Route

from projectmem import __version__
from projectmem.mcp_server import mcp

TOKEN = os.environ.get("MCP_TOKEN", "").strip()
if not TOKEN:
    sys.exit("MCP_TOKEN is empty. Refusing to expose the memory server without a token.")


class BearerAuth(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        if request.url.path == "/health":
            return await call_next(request)
        if request.headers.get("authorization") != f"Bearer {TOKEN}":
            return PlainTextResponse("unauthorized", status_code=401)
        return await call_next(request)


async def health(_request):
    return JSONResponse({"status": "ok", "projectmem": __version__})


# Railway terminates TLS and forwards the public Host header. The SDK's
# DNS-rebinding guard only accepts localhost and would answer 421.
inner = mcp.streamable_http_app(
    transport_security=TransportSecuritySettings(enable_dns_rebinding_protection=False)
)
app = Starlette(
    routes=[Route("/health", health), Mount("/", app=inner)],
    lifespan=inner.router.lifespan_context,
)
app.add_middleware(BearerAuth)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", "8000")), log_level="info")
