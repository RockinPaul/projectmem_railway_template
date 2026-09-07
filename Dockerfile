# projectmem MCP memory server for Railway.
# Upgrade projectmem by bumping the two pins below together (mcp is projectmem's MCP SDK).
FROM python:3.12-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends git \
 && rm -rf /var/lib/apt/lists/* \
 && pip install --no-cache-dir projectmem==0.3.2 mcp==2.2.0

WORKDIR /app
COPY serve.py entrypoint.sh ./
RUN chmod +x entrypoint.sh

ENV PROJECTMEM_HOME=/data/home \
    PROJECTMEM_PROJECTS=default \
    PORT=8000
EXPOSE 8000
ENTRYPOINT ["./entrypoint.sh"]
