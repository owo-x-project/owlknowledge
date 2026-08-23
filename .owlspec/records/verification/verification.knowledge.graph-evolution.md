+++
version = 2
id = "verification.knowledge.graph-evolution"
kind = "verification"
method = "automatic"
target = "test/run.sh"
+++

# Verify useful graph structure evolution

Run `./test/run.sh`. The scenario uses Claim and Source nodes plus supports and contradicts relations, preserves interpreted graph data across rebuild, and exports node/relation structure in stable order for inspection without source paths.
