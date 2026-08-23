+++
version = 2
id = "design.implementation.mcp-server"
kind = "design"
target = "bin/owlknowledge-mcp.awk"
+++

# OwlKnowledge MCP server

The stdio MCP protocol, source registry, derived graph persistence, source-node rebuild, relation traversal, and structure export are implemented here. Notifications without an id execute without emitting a response. Durable source and graph records retain their metadata, while public MCP projections cap result counts and structure lists at 20, text/raw values at 512 bytes, and each tool text projection at 32 KiB. JSON-RPC envelopes and values reject duplicate object keys, require object-or-array `params` when present, cap each request line at 65,536 characters, validate identifiers, require positive integer list limits, and reject empty durable project/status/claim-status/confidence values before writes. Graph arrays, evidence, and source citations are validated before writes; duplicate node ids are rejected, Source node ids (`source-<source_id>`) are reserved against interpreted-node collisions, rebuild preflights collisions before appending, and an unchanged source rebuild is idempotent even when JSON formatting or Unicode escaping differs.

The POSIX shell launcher serializes one request stream per data directory with an exclusive owner-PID lock. It reclaims malformed, dead, or zero-PID locks, removes a lock only when the current process still owns it, and signal cleanup terminates the child AWK process without closing its input stream. The MCP lifecycle honors `shutdown` followed by `exit`, and invalid notifications without ids remain response-free. On reload, only complete records with the expected persisted shape and semantics are admitted; malformed or partial lines, unknown or duplicate citations, dangling graph endpoints, invalid Source-node shapes, empty durable fields, and oversized identifiers are ignored. Duplicate source, node, and edge ids preserve the first valid record. Source ids are limited to 249 characters so their derived Source node ids fit the 256-character graph limit. Optional string metadata is type-checked, graph citation arrays reject duplicate source ids, and escaped Unicode identifiers are decoded consistently, including UTF-16 surrogate pairs.
