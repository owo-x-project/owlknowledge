+++
version = 2
id = "design.implementation.mcp-server"
kind = "design"
target = "bin/owlknowledge-mcp.awk"
+++

# OwlKnowledge MCP server

The stdio MCP protocol, source registry, derived graph persistence, source-node rebuild, relation traversal, and structure export are implemented here. Durable source and graph records retain their metadata, while public MCP projections cap result counts and structure lists at 20 and text/raw values at 512 characters. JSON-RPC envelopes, graph arrays, and evidence are validated, duplicate node ids are rejected, Source node ids (`source-<source_id>`) are reserved against interpreted-node collisions, rebuild preflights collisions before appending, and an unchanged source rebuild is idempotent.
