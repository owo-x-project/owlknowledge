+++
version = 2
id = "verification.knowledge.graph-evolution"
kind = "verification"
method = "automatic"
target = "test/run.sh"
+++

# Verify useful graph structure evolution

Run `./test/run.sh`. The scenario uses Claim and Source nodes plus supports and contradicts relations, preserves interpreted graph data across rebuild, verifies that an unchanged rebuild is idempotent, and exports node/relation structure in stable bounded order for inspection without source paths.

The regression cases also cover wrong optional types, duplicate object keys, invalid `params` shapes, oversized requests, invalid positive-integer limits, duplicate source citations, escaped/raw Unicode source-id equivalence including surrogate pairs, source ids too long for a derived Source node, partial and semantically invalid persisted source/node/edge lines on restart, dangling endpoints, malformed lock-owner recovery, signal-safe owner-only lock cleanup, and concurrent source registration and node writes without lost records.
