#!/bin/bash

PORT=8092
NAME="lightrag-mcp"

#docker rm -f lightrag-mcp

docker run -d --restart unless-stopped -it \
  --add-host=host.docker.internal:host-gateway \
  -p $PORT:$PORT --name $NAME \
  -e PORT=$PORT -e LIGHTRAG_API_PORT=9621 -e LIGHTRAG_API_HOST="host.docker.internal" \
  lightrag-mcp
