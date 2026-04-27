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

# Install only essential runtime dependencies (no nodejs/npm needed)
RUN apk add --no-cache bash curl ca-certificates || \
    (echo "HTTPS repositories failed, trying HTTP..." && \
     echo "http://dl-cdn.alpinelinux.org/alpine/v3.22/main" > /etc/apk/repositories && \
     echo "http://dl-cdn.alpinelinux.org/alpine/v3.22/community" >> /etc/apk/repositories && \
     apk add --no-cache bash curl ca-certificates)

# Copy the Python virtualenv from the build stage
COPY --from=uv --chown=app:app /app/.venv /app/.venv

# Copy uv binary from the build stage to enable uv and uvx commands
COPY --from=uv /usr/local/bin/uv /usr/local/bin/uv

# Copy the project files
COPY --from=uv /app /app

# Variabili d'ambiente
ENV PATH="/app/.venv/bin:$PATH"
ENV LIGHTRAG_API_HOST="localhost"
ENV LIGHTRAG_API_PORT="9621"
ENV LIGHTRAG_API_KEY=""
ENV MCP_HOST="0.0.0.0"
ENV MCP_PORT="8092"

WORKDIR /app

# Install the package to make it available in the venv
RUN uv pip install -e . || \
    (echo "SSL verification failed, retrying with insecure mode..." && \
     PYTHONHTTPSVERIFY=0 UV_INSECURE_HOST="*" uv pip install -e .)

# Esponi porta MCP HTTP
EXPOSE 8092

# Avvio diretto — lightrag-mcp legge MCP_HOST/MCP_PORT/LIGHTRAG_API_* da env vars
ENTRYPOINT ["lightrag-mcp"]
