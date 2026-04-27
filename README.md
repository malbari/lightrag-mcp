[![MseeP.ai Security Assessment Badge](https://mseep.net/pr/shemhamforash23-lightrag-mcp-badge.png)](https://mseep.ai/app/shemhamforash23-lightrag-mcp)

# LightRAG MCP Server

MCP server for integrating LightRAG with AI tools. Provides a unified interface for interacting with LightRAG API through the MCP protocol.

## Description

LightRAG MCP Server is a bridge between LightRAG API and MCP-compatible clients. It allows using LightRAG (Retrieval-Augmented Generation) capabilities in various AI tools that support the MCP protocol.

### Key Features

- **Information Retrieval**: Execute semantic and keyword queries to documents
- **Document Management**: Upload, index, and track document status
- **Knowledge Graph Operations**: Manage entities and relationships in the knowledge graph
- **Monitoring**: Check LightRAG API status and document processing

## Installation

This server is designed to be used as an MCP server and should be installed in a virtual environment using uv, not as a system-wide package.

### Development Installation

```bash
# Create a virtual environment
uv venv --python 3.11

# Install the package in development mode
uv pip install -e .
```

## Requirements

- Python 3.11+
- Running LightRAG API server

## Usage

The server exposes a **Streamable HTTP** MCP endpoint at `http://<host>:<port>/mcp` (default port: `8092`).

### Command Line Options (LightRAG API connection)

The following arguments configure the connection to the LightRAG API backend. They can also be set via environment variables:

| Argument | Env var | Default | Description |
|---|---|---|---|
| `--host` | `LIGHTRAG_API_HOST` | `localhost` | LightRAG API host |
| `--port` | `LIGHTRAG_API_PORT` | `9621` | LightRAG API port |
| `--api-key` | `LIGHTRAG_API_KEY` | *(none)* | LightRAG API key |

The MCP HTTP server port is controlled exclusively by environment variables:

| Env var | Default | Description |
|---|---|---|
| `MCP_HOST` | `0.0.0.0` | Bind address for the MCP HTTP server |
| `MCP_PORT` | `8092` | Port for the MCP HTTP server |

### Integration with LightRAG API

The MCP server requires a running LightRAG API server. Start it as follows:

```bash
# Create virtual environment
uv venv --python 3.11

# Install dependencies
uv pip install -r LightRAG/lightrag/api/requirements.txt

# Start LightRAG API
uv run LightRAG/lightrag/api/lightrag_server.py --host localhost --port 9621 --working-dir ./rag_storage --input-dir ./input --llm-binding openai --embedding-binding openai --log-level DEBUG
```

### Running with Docker

```bash
# Build the image
./build-image.sh

# Start the container
./start.sh

# The MCP endpoint is available at:
# http://localhost:8092/mcp
```

You can override the defaults at runtime:

```bash
docker run -d --restart unless-stopped \
  --add-host=host.docker.internal:host-gateway \
  -p 8092:8092 --name lightrag-mcp \
  -e LIGHTRAG_API_HOST="host.docker.internal" \
  -e LIGHTRAG_API_PORT=9621 \
  -e LIGHTRAG_API_KEY="your_api_key" \
  -e MCP_PORT=8092 \
  lightrag-mcp
```

### Connecting an MCP client

Configure your MCP client (e.g., VS Code Copilot, Claude Desktop) with the HTTP transport:

```json
{
  "mcpServers": {
    "lightrag-mcp": {
      "type": "http",
      "url": "http://localhost:8092/mcp"
    }
  }
}
```

#### Development (local run without Docker)

```bash
# Install dependencies
uv pip install -e .

# Start the server
lightrag-mcp --host localhost --port 9621
```

Then connect your MCP client to `http://localhost:8092/mcp`.

## Available MCP Tools

### Document Queries
- `query_document`: Execute a query to documents through LightRAG API

### Document Management
- `insert_document`: Add text directly to LightRAG storage
- `upload_document`: Upload document from file to the /input directory
- `insert_file`: Add document from file directly to storage
- `insert_batch`: Add batch of documents from directory
- `scan_for_new_documents`: Start scanning the /input directory for new documents
- `get_documents`: Get list of all uploaded documents
- `get_pipeline_status`: Get status of document processing in pipeline

### Knowledge Graph Operations
- `get_graph_labels`: Get labels (node and relationship types) from knowledge graph
- `create_entities`: Create multiple entities in knowledge graph
- `edit_entities`: Edit multiple existing entities in knowledge graph
- `delete_by_entities`: Delete multiple entities from knowledge graph by name
- `delete_by_doc_ids`: Delete all entities and relationships associated with multiple documents
- `create_relations`: Create multiple relationships between entities in knowledge graph
- `edit_relations`: Edit multiple relationships between entities in knowledge graph
- `merge_entities`: Merge multiple entities into one with relationship migration

### Monitoring
- `check_lightrag_health`: Check LightRAG API status

## Development

### Installing development dependencies

```bash
uv pip install -e ".[dev]"
```

### Running linters

```bash
ruff check src/
mypy src/
```

## License

MIT
