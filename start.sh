#!/bin/bash

PORT=8082
NAME="lightrag-mcp"

#docker rm -f lightrag-mcp

docker run -d --restart unless-stopped -it \
  --add-host=host.docker.internal:host-gateway \
  -p $PORT:$PORT --name $NAME \
  -e PORT=$PORT -e LIGHTRAG_PORT=30010 -e LIGHTRAG_HOST="10.17.2.8" \
  lightrag-mcp
