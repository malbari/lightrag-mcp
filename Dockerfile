# Build stage with explicit platform specification
FROM ghcr.io/astral-sh/uv:python3.12-alpine AS uv

WORKDIR /app

ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy

# Try with SSL first, fallback to insecure if needed (for corporate proxies like Zscaler)
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev --no-editable || \
    (echo "SSL verification failed, retrying with insecure mode..." && \
     PYTHONHTTPSVERIFY=0 UV_INSECURE_HOST="*" uv sync --frozen --no-install-project --no-dev --no-editable)

ADD . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable || \
    (echo "SSL verification failed, retrying with insecure mode..." && \
     PYTHONHTTPSVERIFY=0 UV_INSECURE_HOST="*" uv sync --frozen --no-dev --no-editable)

# Final stage with explicit platform specification
FROM python:3.12-alpine

# Set environment variables for corporate proxy fallback
ENV NODE_TLS_REJECT_UNAUTHORIZED=0

# Try HTTPS repositories first, fallback to HTTP if needed
RUN apk add --no-cache nodejs npm bash curl ca-certificates || \
    (echo "HTTPS repositories failed, trying HTTP..." && \
     echo "http://dl-cdn.alpinelinux.org/alpine/v3.22/main" > /etc/apk/repositories && \
     echo "http://dl-cdn.alpinelinux.org/alpine/v3.22/community" >> /etc/apk/repositories && \
     apk add --no-cache nodejs npm bash curl ca-certificates)

# Copy the Python virtualenv from the build stage
COPY --from=uv --chown=app:app /app/.venv /app/.venv

# Copy uv binary from the build stage to enable uv and uvx commands
COPY --from=uv /usr/local/bin/uv /usr/local/bin/uv

# Create uvx symlink for uvx commands
RUN ln -s /usr/local/bin/uv /usr/local/bin/uvx

# Install mcp-proxy using uv tool install
RUN uv tool install mcp-proxy || \
    (echo "SSL verification failed, retrying with insecure mode..." && \
     PYTHONHTTPSVERIFY=0 UV_INSECURE_HOST="*" uv tool install mcp-proxy)

# Copy the project files to enable uvx to find the package
COPY --from=uv /app /app

# Variabili d'ambiente
ENV PATH="/root/.local/bin:/app/.venv/bin:$PATH"
ENV MCP_PROXY_HOST="0.0.0.0"
ENV MCP_PROXY_PORT="8092"
ENV LIGHTRAG_API_HOST="localhost"
ENV LIGHTRAG_API_PORT="9621"

WORKDIR /app

# Install the package to make it available to uvx
RUN uv pip install -e . || \
    (echo "SSL verification failed, retrying with insecure mode..." && \
     PYTHONHTTPSVERIFY=0 UV_INSECURE_HOST="*" uv pip install -e .)

# Esponi porta configurabile (default)
EXPOSE 8082

# Crea script di avvio che usa variabili d'ambiente a runtime
RUN printf '#!/bin/sh\n' > /app/start.sh && \
    printf 'exec mcp-proxy --port "${MCP_PROXY_PORT}" --host "${MCP_PROXY_HOST:-0.0.0.0}" --pass-environment -- lightrag-mcp --host "${LIGHTRAG_API_HOST}" --port "${LIGHTRAG_API_PORT}"\n' >> /app/start.sh && \
    chmod +x /app/start.sh

# Avvio con script
ENTRYPOINT ["/app/start.sh"]
