# OwlKnowledge implementation

OwlKnowledge is an MCP server that keeps source references as durable material and a knowledge graph as a revisable, derived interpretation. It does not assert graph claims as project decisions or specifications.

## Run

```sh
OWL_KNOWLEDGE_DATA_DIR=.owlknowledge ./bin/owlknowledge-mcp
```

The process speaks newline-delimited JSON-RPC over stdin/stdout. Its only product interface is MCP. The launcher is POSIX `sh`; the server is POSIX `awk` and has no Python, jq, SQLite, HTTP server, or MCP SDK dependency.

The data directory contains JSON Lines files:

- `sources.jsonl` is the durable source registry. It stores references and uncertainty/status metadata, not a rewritten copy of source contents.
- `nodes.jsonl` and `edges.jsonl` are derived graph state. Updates append a new state line; `rebuild_graph` refreshes Source nodes while preserving interpreted nodes and edges, without changing `sources.jsonl`.

Source formats are intentionally open: paths, URLs, Markdown, PDF, papers, meetings, experiments, code, and external specifications are all references. Source `status` and optional `uncertainty` are preserved verbatim. Interpreted claims retain `source_ids`, `claim_status`, and `confidence`; contradictory material is represented with independent nodes and a `contradicts` edge rather than being merged.

Required source metadata cannot be empty, malformed graph arrays or edge evidence are rejected, graph identifiers must be non-empty and at most 256 characters, and graph nodes or relations cannot cite a source that is not registered. Every search and traversal result is hard-capped at 20 items and reports whether more matching data was omitted. All public metadata text is projected to at most 512 characters; source-id arrays and structure type/relation lists report their full count when truncated. Traversal preserves node labels, source references, claim state, confidence, and source-id provenance; descriptions are bounded and arbitrary edge Evidence is represented by a presence flag. Search results, rebuilt Source nodes, graph traversal, and exported structure use stable identifier order, and rebuilding an unchanged source graph is idempotent, so bounded context remains repeatable.

## MCP surface

Use `discover` first when routing is unclear. The public tools register/search sources, rebuild the derived graph, add nodes/relations, trace bounded one-hop context, and export structure. Initial relation names include `references`, `supports`, `contradicts`, `derived-from`, `related-to`, and `evaluates`, while the graph can evolve with additional relation names when useful. The `owlknowledge://structure` resource exports only types and relations; use bounded `traverse_graph` for targeted derived context.

`export_structure` is safe to share without project-specific source content. The `owlknowledge://structure` resource is intentionally the only graph resource: use `traverse_graph` for targeted context instead of loading the whole graph into an agent context. `rebuild_graph` is the recovery path after adding sources or refreshing source interpretation: source records and existing interpreted graph data remain intact, and every source can always produce a Source node again.

## Verification

```sh
./test/run.sh
```
