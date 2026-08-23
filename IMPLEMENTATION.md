# OwlKnowledge implementation

OwlKnowledge is an MCP server that keeps source references as durable material and a knowledge graph as a revisable, derived interpretation. It does not assert graph claims as project decisions or specifications.

## Run

```sh
OWL_KNOWLEDGE_DATA_DIR=.owlknowledge ./bin/owlknowledge-mcp
```

The process speaks newline-delimited JSON-RPC over stdin/stdout. Notifications without an id are executed without emitting a response. Its only product interface is MCP. The launcher is POSIX `sh`; the server is POSIX `awk` and has no Python, jq, SQLite, HTTP server, or MCP SDK dependency. The launcher takes an exclusive lock for the selected data directory for the lifetime of one request stream, so separate `codex exec` or MCP processes cannot calculate IDs or append state concurrently. The lock records an owner PID, reclaims malformed or dead-owner locks, and only the owning process may remove it; signal cleanup also terminates the child AWK process while preserving its input stream. A stale lock owned by a dead process is reclaimed.

The data directory contains JSON Lines files:

- `sources.jsonl` is the durable source registry. It stores references and uncertainty/status metadata, not a rewritten copy of source contents.
- `nodes.jsonl` and `edges.jsonl` are derived graph state. Updates append a new state line; `rebuild_graph` refreshes Source nodes while preserving interpreted nodes and edges, without changing `sources.jsonl`.

Source formats are intentionally open: paths, URLs, Markdown, PDF, papers, meetings, experiments, code, and external specifications are all references. Source `status` and optional `uncertainty` are preserved verbatim. Interpreted claims retain `source_ids`, `claim_status`, and `confidence`; contradictory material is represented with independent nodes and a `contradicts` edge rather than being merged.

Malformed JSON-RPC request lines, duplicate JSON object keys, non-object/non-array `params`, request lines longer than 65,536 characters, malformed or partial persisted JSONL records, empty source metadata, empty required project/status/claim-status/confidence fields, wrong types for optional string metadata, duplicate source ids in a citation list, malformed graph arrays or edge evidence are rejected or ignored on reload. Fields required by the durable model cannot be written as empty strings that would later disappear during reload. Graph identifiers must be non-empty and at most 256 characters; source identifiers are limited to 249 characters so the derived `source-<source_id>` node also fits the graph limit. Persisted sources, nodes, and edges are semantically revalidated on reload: unknown or duplicate citations, dangling endpoints, invalid Source-node shape, and oversized identifiers are ignored, and duplicate source/node/edge ids preserve the first valid record. `limit` must be a positive integer and every search and traversal result is hard-capped at 20 items, reporting whether more matching data was omitted. Graph nodes or relations cannot cite a source that is not registered. JSON Unicode escapes, including surrogate pairs, are decoded to the same identifiers as their raw UTF-8 form. Source-node identifiers (`source-<source_id>`) are reserved: interpreted nodes cannot shadow them, source registration rejects an existing collision, and rebuild preflights collisions before appending anything. All public metadata text is projected to at most 512 bytes; source-id arrays and structure type/relation lists report their full count when truncated. Traversal preserves node labels, source references, claim state, confidence, and source-id provenance; descriptions are bounded and arbitrary edge Evidence is represented by a presence flag. Search results, rebuilt Source nodes, graph traversal, and exported structure use stable identifier order, and rebuilding an unchanged source graph is idempotent even when persisted JSON formatting or Unicode escaping differs, so bounded context remains repeatable. Each tool text projection is capped at 32 KiB and replaced by a compact truncation marker when the bounded item set would exceed that budget. The launcher reclaims malformed, dead, or zero-PID locks, and the MCP lifecycle honors `shutdown` followed by `exit` while suppressing invalid notifications without ids.

## MCP surface

Use `discover` first when routing is unclear. The public tools register/search sources, rebuild the derived graph, add nodes/relations, trace bounded one-hop context, and export structure. Initial relation names include `references`, `supports`, `contradicts`, `derived-from`, `related-to`, and `evaluates`, while the graph can evolve with additional relation names when useful. The `owlknowledge://structure` resource exports only types and relations; use bounded `traverse_graph` for targeted derived context.

`export_structure` is safe to share without project-specific source content. The `owlknowledge://structure` resource is intentionally the only graph resource: use `traverse_graph` for targeted context instead of loading the whole graph into an agent context. `rebuild_graph` is the recovery path after adding sources or refreshing source interpretation: source records and existing interpreted graph data remain intact, and every source can always produce a Source node again.

## Verification

```sh
./test/run.sh
```
