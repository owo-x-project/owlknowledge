+++
version = 2
id = "verification.knowledge.rebuildable-graph"
kind = "verification"
method = "automatic"
target = "test/run.sh"
+++

# Verify source-preserving graph rebuild

Run `./test/run.sh`. The scenario rebuilds Source nodes, adds interpreted nodes and edges, rebuilds again, and confirms the source records and interpreted graph remain addressable.
