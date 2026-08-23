+++
version = 2
id = "design.implementation.mcp-server"
kind = "design"
target = "bin/owlknowledge-mcp.awk"
+++

# OwlKnowledge MCP server

The stdio MCP protocol, source registry, derived graph persistence, source-node rebuild, relation traversal, and structure export are implemented here. Notifications without an id execute without emitting a response. Durable source and graph records retain their metadata, while public MCP projections cap result counts and structure lists at 20 and text/raw values at 512 characters. JSON-RPC envelopes, graph arrays, and evidence are validated, duplicate node ids are rejected, Source node ids (`source-<source_id>`) are reserved against interpreted-node collisions, rebuild preflights collisions before appending, and an unchanged source rebuild is idempotent.

The POSIX shell launcher serializes one request stream per data directory with an exclusive lock and reclaims locks whose owner is no longer alive, preventing concurrent codex exec or MCP processes from losing append-only updates or reusing generated ids. On reload, only complete JSON records with the expected persisted shape are admitted; malformed or partial lines are ignored. Optional string metadata is type-checked, graph citation arrays reject duplicate source ids, and escaped Unicode identifiers are decoded consistently, including UTF-16 surrogate pairs.
