+++
version = 2
id = "verification.knowledge.graph-evolution"
kind = "verification"
method = "automatic"
target = "test/run.sh"
+++

# Verify useful graph structure evolution

Run `./test/run.sh`. The scenario uses Claim and Source nodes plus supports and contradicts relations, preserves interpreted graph data across rebuild, verifies that an unchanged rebuild is idempotent, and exports node/relation structure in stable bounded order for inspection without source paths.
