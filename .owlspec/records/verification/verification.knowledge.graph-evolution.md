+++
version = 2
id = "verification.knowledge.graph-evolution"
kind = "verification"
method = "automatic"
target = "test/run.sh"
+++

# Verify useful graph structure evolution

Run `./test/run.sh`. The scenario uses Claim and Source nodes plus supports and contradicts relations, preserves interpreted graph data across rebuild, verifies that an unchanged rebuild is idempotent, and exports node/relation structure in stable bounded order for inspection without source paths.

The regression cases also cover wrong optional types, empty durable source/node fields, duplicate object keys, invalid notifications, invalid `params` shapes, oversized requests, invalid positive-integer limits, duplicate source citations, escaped/raw Unicode source-id equivalence including surrogate pairs under `LC_ALL=C`, semantic Source-node reload and rebuild independent of JSON formatting, source ids too long for a derived Source node, duplicate source/node/edge lines preserving first facts, partial and semantically invalid persisted source/node/edge lines on restart, dangling endpoints, malformed/dead/zero-PID lock recovery, signal-safe owner-only lock cleanup, shutdown/exit lifecycle, bounded source projections, aggregate 32 KiB tool-text projections, and concurrent source registration and node writes without lost records.
