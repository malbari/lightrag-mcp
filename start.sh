#!/bin/bash

PORT=8092
NAME="lightrag-mcp"

# With OrbStack, host.docker.internal doesn't route correctly.
# Use the bridge gateway IP to reach the host from the container.
HOST_IP=$(docker network inspect bridge --format '{{range .IPAM.Config}}{{.Gateway}}{{end}}' 2>/dev/null)
if [ -z "$HOST_IP" ]; then
  HOST_IP="host.docker.internal"
fi

docker run -d --restart unless-stopped -it \
  --add-host=host.docker.internal:host-gateway \
  -p $PORT:$PORT --name $NAME \
  -e PORT=$PORT -e LIGHTRAG_API_PORT=9621 -e LIGHTRAG_API_HOST="$HOST_IP" \
  lightrag-mcp
